# Bootstrap Subrepos Workflow - Pseudo Code

## Workflow Triggers
- **Manual dispatch** with force option (true/false)
- **Repository creation** events
- **Repository dispatch** with 'bootstrap' type

## Main Algorithm Flow

```
FUNCTION bootstrap_workflow():
    checkout_repository(fetch_depth=0, token=GH_TOKEN)
    setup_git_user("GitHub Actions", "actions@github.com")

    config_analysis = parse_subrepo_configuration()
    subrepo_count = config_analysis.total_count
    force_clone = input.force_parameter

    bootstrap_script = create_bootstrap_script()
    execute_bootstrap_process(bootstrap_script)
    verify_bootstrap_results()
    commit_and_push_changes()
    create_bootstrap_summary()
```

## Bootstrap Process Details

```
FUNCTION create_bootstrap_script():
    SET force_clone = workflow_input.force
    SET config_file = ".github/subrepo-config.json"
    SET parallel_batch_size = 10

    INITIALIZE counters:
        success_count = 0
        skip_count = 0
        error_count = 0

    CREATE error_log_file()

    FOR EACH subrepo IN config_file:
        PARALLEL_EXECUTE bootstrap_subrepo(subrepo) WITH batch_limit=10

    WAIT_FOR_ALL_PARALLEL_JOBS()

    IF error_count > 0:
        EXIT_WITH_FAILURE()

    RETURN summary_report
```

## Individual Repository Bootstrap

```
FUNCTION bootstrap_subrepo(prefix, remote, branch):
    IF directory_exists(prefix) AND has_content(prefix) AND NOT force_clone:
        skip_count++
        RETURN success

    CREATE_DIRECTORY(prefix)

    TRY:
        clone_repository(remote, branch, temporary_location)
        move_content_to_target(temporary_location, prefix)
        remove_git_directory(prefix + "/.git")  # Integrate with monorepo
        success_count++
        RETURN success
    CATCH clone_error:
        log_error(remote, prefix, error_details)
        error_count++
        RETURN failure
```

## Post-Bootstrap Operations

```
FUNCTION verify_bootstrap_results():
    total_expected = config.subrepo_count
    found_directories = 0

    FOR EACH subrepo IN configuration:
        IF directory_exists(subrepo.prefix) AND has_content(subrepo.prefix):
            found_directories++
        ELSE:
            log_warning("Missing or empty: " + subrepo.prefix)

    RETURN verification_report(found_directories, total_expected)
```

```
FUNCTION commit_and_push_changes():
    IF git_has_changes():
        git_add_all()
        git_commit("chore: bootstrap subrepos [skip ci]")
        git_push_to_main()
    ELSE:
        log("No changes detected after bootstrap")
```

## Error Handling and Reporting

```
FUNCTION create_bootstrap_summary():
    summary = {
        date: current_timestamp,
        triggered_by: workflow_actor,
        force_clone: input_parameter,
        results: process_logs
    }

    IF errors_exist():
        summary.errors = read_error_log()

    upload_artifact(summary)
```

## Key Implementation Notes

- **Parallel Processing**: Maximum 10 concurrent repository clones
- **Git Integration**: Removes .git directories to integrate with monorepo structure
- **Force Option**: Allows re-cloning existing repositories
- **Error Recovery**: Continues processing other repositories if individual failures occur
- **State Management**: Uses directory presence and content to determine if bootstrap needed
- **Artifact Upload**: Creates summary artifacts for all workflow runs (success or failure)

## Critical State Handling

- **Skip Logic**: Existing populated directories are skipped unless force=true
- **Cleanup**: Temporary clone directories are cleaned up on both success and failure
- **Commit Strategy**: Only commits if actual changes are detected
- **CI Skip**: Uses `[skip ci]` to prevent triggering other workflows during bootstrap