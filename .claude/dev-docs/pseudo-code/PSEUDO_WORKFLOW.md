### Unified Synchronization Workflow
# Workflow: "Monorepo Synchronization"
# Triggers:
#   - push:
#       branches: [main]
#   - pull_request:
#       branches: [main]
#   - schedule:
#       - cron: "0 * * * *"  # Hourly
#   - workflow_dispatch:

### Helper Functions

FUNCTION check_repository_exists(repo_name):
    # Check if the repository exists using GitHub API
    GET repo_exists = gh api /repos/${repo_name}
    RETURN repo_exists.status == 200
END FUNCTION

FUNCTION check_local_git_exists(prefix_path):
    RETURN directory_exists(prefix_path + "/.git")
END FUNCTION

FUNCTION identify_changed_files():
    # Get list of modified files from push event
    GET changed_files = gh api /repos/${repo}/commits/${commit_sha}/files
    RETURN changed_files
END FUNCTION

FUNCTION map_files_to_subrepos(changed_files, subrepo_config):
    SET affected_subrepos = empty_map()
    
    FOR EACH file IN changed_files:
        FOR EACH subrepo IN subrepo_config:
            IF file.path.startswith(subrepo.prefix):
                ADD subrepo TO affected_subrepos
            END IF
        END FOR
    END FOR
    
    RETURN affected_subrepos
END FUNCTION

FUNCTION check_remote_divergence(subrepo):
    GET remote_head = gh api /repos/${subrepo.remote}/commits/main
    IF remote_head != subrepo.last_known_commit:
        RETURN true
    END IF
    RETURN false
END FUNCTION

### Workflow Jobs

# Job 1: Analysis & Planning
JOB analyze_changes:
    needs: []
    runs-on: ubuntu-latest
    outputs: execution_plan
    
    FUNCTION generate_execution_plan(affected_subrepos):
        SET execution_matrix = empty_list()
        
        FOR EACH subrepo IN affected_subrepos:
            SET action = ""
            
            # Determine required action
            IF NOT check_repository_exists(subrepo.remote) OR NOT check_local_git_exists(subrepo.prefix):
                SET action = "bootstrap"
            ELSE IF check_remote_divergence(subrepo):
                SET action = "report_divergence"
            ELSE:
                SET action = "sync"
            END IF
            
            ADD {
                "subrepo": subrepo,
                "action": action
            } TO execution_matrix
        END FOR
        
        RETURN execution_matrix
    END FUNCTION

    # Main job execution
    IF github.event_name IN ["push", "pull_request"]:
        SET changed_files = CALL identify_changed_files()
        SET affected_subrepos = CALL map_files_to_subrepos(changed_files, load_subrepo_config())
        SET execution_plan = CALL generate_execution_plan(affected_subrepos)
        RETURN execution_plan
    END IF
END JOB

# Job 2: Split & Sync Matrix
JOB process_subrepos:
    needs: [analyze_changes]
    runs-on: ubuntu-latest
    strategy:
        matrix: ${{ fromJson(needs.analyze_changes.outputs.execution_plan) }}
    
    FUNCTION bootstrap_subrepo(subrepo):
        # Create remote repository if it doesn't exist
        IF NOT check_repository_exists(subrepo.remote):
            CALL gh repo create ${subrepo.remote} --public
        END IF
        
        # Initialize local git and perform split
        CALL git init ${subrepo.prefix}
        CALL git subtree split --prefix=${subrepo.prefix}
        CALL git push ${subrepo.remote} main
    END FUNCTION

    FUNCTION sync_subrepo(subrepo):
        SET temp_branch = "sync-" + generate_timestamp()
        
        # Perform subtree split and create PR
        CALL git subtree split --prefix=${subrepo.prefix}
        CALL git push ${subrepo.remote} ${temp_branch}
        CALL gh pr create --repo ${subrepo.remote} --base main --head ${temp_branch}
    END FUNCTION

    # Main job execution
    IF matrix.action == "bootstrap":
        CALL bootstrap_subrepo(matrix.subrepo)
    ELSE IF matrix.action == "sync":
        CALL sync_subrepo(matrix.subrepo)
    ELSE IF matrix.action == "report_divergence":
        PRINT "Warning: Divergence detected for " + matrix.subrepo.remote
    END IF
END JOB

# Job 3: Cleanup
JOB cleanup_monorepo:
    needs: [process_subrepos]
    runs-on: ubuntu-latest
    if: success() && github.event_name == 'push'
    
    FUNCTION cleanup_monorepo(successful_syncs):
        SET cleanup_branch = "cleanup-" + generate_timestamp()
        
        # Create branch for cleanup
        CALL git checkout -b ${cleanup_branch}
        
        FOR EACH subrepo IN successful_syncs:
            CALL git rm -r ${subrepo.prefix}
        END FOR
        
        CALL git commit -m "Cleanup: Remove synchronized directories"
        CALL gh pr create --base main --head ${cleanup_branch}
    END FUNCTION

    # Main job execution
    SET successful_syncs = CALL get_successful_syncs()
    IF NOT empty(successful_syncs):
        CALL cleanup_monorepo(successful_syncs)
    END IF
END JOB

# Job 4: Summary
JOB post_summary:
    needs: [cleanup_monorepo]
    runs-on: ubuntu-latest
    if: always()
    
    # Main job execution
    CALL post_summary_comment(execution_plan)
END JOB

# Job 5: Downstream Sync (Scheduled/Manual)
JOB downstream_sync:
    needs: []
    runs-on: ubuntu-latest
    if: github.event_name IN ['schedule', 'workflow_dispatch']
    
    FUNCTION handle_scheduled_sync():
        SET subrepo_config = load_subrepo_config()
        SET changes_detected = false
        
        FOR EACH subrepo IN subrepo_config:
            TRY:
                CALL git subtree pull --prefix=${subrepo.prefix} ${subrepo.remote} main
                SET changes_detected = true
            CATCH merge_conflict:
                PRINT "Merge conflict detected in " + subrepo.remote
                RETURN error
            END TRY
        END FOR
        
        IF changes_detected:
            SET sync_branch = "downstream-sync-" + generate_timestamp()
            CALL git checkout -b ${sync_branch}
            CALL git commit -m "Downstream sync: Pull changes from subrepos"
            CALL gh pr create --base main --head ${sync_branch}
        END IF
    END FUNCTION

    # Main job execution
    CALL handle_scheduled_sync()
END JOB
