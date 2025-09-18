# Sync from Upstream Workflow - Pseudo Code

## Workflow Triggers
- **Scheduled execution** daily at 2 AM UTC
- **Manual dispatch** with upstream_repo, upstream_branch, and force_sync parameters

## Main Algorithm Flow

```
FUNCTION sync_upstream_workflow():
    upstream_config = configure_upstream_repository()

    IF upstream_config.configured:
        change_analysis = fetch_and_analyze_upstream_changes()

        IF change_analysis.has_changes:
            sync_results = create_sync_branch_and_merge()

            IF sync_results.merge_success:
                distribute_changes_to_subrepos()
                create_upstream_sync_pull_request()
            ELSE:
                handle_merge_conflicts(sync_results.conflicts)

    create_sync_summary()
```

## Upstream Configuration

```
FUNCTION configure_upstream_repository():
    checkout_repository(fetch_depth=0)
    setup_git_configuration()

    upstream_repo = determine_upstream_repository()

    IF upstream_repo.is_empty():
        log_warning("No upstream repository configured")
        RETURN {configured: false}

    setup_upstream_remote(upstream_repo)

    RETURN {
        configured: true,
        upstream_repo: upstream_repo
    }
```

```
FUNCTION determine_upstream_repository():
    # Priority: manual input > environment default
    IF input.upstream_repo.is_set():
        RETURN input.upstream_repo
    ELIF environment.DEFAULT_UPSTREAM.is_set():
        RETURN environment.DEFAULT_UPSTREAM
    ELSE:
        RETURN empty_string
```

```
FUNCTION setup_upstream_remote(upstream_repo):
    upstream_url = "https://github.com/" + upstream_repo + ".git"

    IF NOT git_remote_exists("upstream"):
        git_remote_add("upstream", upstream_url)
    ELSE:
        git_remote_set_url("upstream", upstream_url)

    log_info("Upstream configured: " + upstream_repo)
```

## Change Detection and Analysis

```
FUNCTION fetch_and_analyze_upstream_changes():
    upstream_branch = input.upstream_branch || "main"

    git_fetch("upstream", upstream_branch)

    change_analysis = analyze_commit_differences(upstream_branch)

    RETURN change_analysis
```

```
FUNCTION analyze_commit_differences(upstream_branch):
    local_branch = git_get_current_branch()

    commits_behind = git_count_commits("HEAD..upstream/" + upstream_branch)
    commits_ahead = git_count_commits("upstream/" + upstream_branch + "..HEAD")

    log_info("Local branch is " + commits_behind + " commits behind and " + commits_ahead + " commits ahead")

    has_changes = (commits_behind > 0) OR input.force_sync

    RETURN {
        behind: commits_behind,
        ahead: commits_ahead,
        has_changes: has_changes
    }
```

## Sync Branch Creation and Merge

```
FUNCTION create_sync_branch_and_merge():
    sync_branch = "sync-upstream-" + timestamp()
    git_checkout_new_branch(sync_branch)

    merge_results = attempt_upstream_merge()

    RETURN {
        branch: sync_branch,
        merge_success: merge_results.success,
        conflicts: merge_results.conflicts
    }
```

```
FUNCTION attempt_upstream_merge():
    upstream_branch = input.upstream_branch || "main"

    TRY:
        git_merge("upstream/" + upstream_branch, no_edit=true)
        log_success("Successfully merged upstream changes")
        RETURN {success: true}
    CATCH merge_conflict:
        log_warning("Merge conflicts detected")
        conflicted_files = git_get_conflicted_files()
        RETURN {
            success: false,
            conflicts: conflicted_files
        }
```

## Subrepo Distribution Analysis

```
FUNCTION distribute_changes_to_subrepos():
    # Get changed files from the merge
    changed_files = git_diff_name_only("HEAD~1..HEAD")

    affected_subrepos = map_files_to_affected_subrepos(changed_files)

    IF affected_subrepos.length > 0:
        log_info("Affected subrepos:")
        log_list(affected_subrepos)
        write_file("affected_subrepos.txt", affected_subrepos)
        log_info("Distribution will happen automatically via push-subrepos workflow")
    ELSE:
        log_info("No subrepo changes detected in upstream sync")
```

```
FUNCTION map_files_to_affected_subrepos(changed_files):
    config = load_subrepo_configuration()
    affected_subrepos = []

    FOR EACH file IN changed_files:
        FOR EACH subrepo IN config.subrepos:
            IF file.startswith(subrepo.prefix + "/"):
                add_unique(affected_subrepos, subrepo.prefix)

    RETURN affected_subrepos
```

## Pull Request Creation

```
FUNCTION create_upstream_sync_pull_request():
    sync_branch = current_branch
    git_push_branch(sync_branch)

    pr_body = build_upstream_sync_pr_body()

    github_create_pull_request(
        title="⬆️ Sync: Update from upstream (" + upstream_repo + ")",
        body=pr_body,
        base="main",
        head=sync_branch,
        labels=["upstream-sync", "automated"]
    )
```

```
FUNCTION build_upstream_sync_pr_body():
    affected_subrepos = read_affected_subrepos_if_exists()

    body = "This PR syncs changes from the upstream repository.\n\n"
    body += "## Upstream Details\n"
    body += "- **Repository:** " + upstream_repo + "\n"
    body += "- **Branch:** " + upstream_branch + "\n"
    body += "- **Commits behind:** " + commits_behind + "\n"
    body += "- **Commits ahead:** " + commits_ahead + "\n\n"

    body += "## Sync Information\n"
    body += "- **Time:** " + current_timestamp() + "\n"
    body += "- **Triggered by:** " + github.event_name + "\n"
    body += "- **Force sync:** " + input.force_sync + "\n\n"

    IF affected_subrepos.length > 0:
        body += "### Affected Subrepos\n"
        body += "```\n" + join(affected_subrepos, "\n") + "\n```\n\n"

    body += "## Next Steps\n"
    body += "1. Review the changes\n"
    body += "2. Resolve any conflicts if present\n"
    body += "3. Merge to trigger automatic distribution to subrepos\n\n"
    body += "---\n"
    body += "*This PR was automatically generated by the upstream sync workflow.*\n"

    RETURN body
```

## Conflict Handling

```
FUNCTION handle_merge_conflicts(conflicts):
    # Abort the failed merge
    git_merge_abort()

    create_conflict_resolution_issue(conflicts)
```

```
FUNCTION create_conflict_resolution_issue(conflicts):
    issue_body = build_conflict_issue_body(conflicts)

    github_create_issue(
        title="⚠️ Upstream sync conflicts with " + upstream_repo,
        body=issue_body,
        labels=["conflict", "upstream-sync", "needs-attention"]
    )
```

```
FUNCTION build_conflict_issue_body(conflicts):
    body = "Merge conflicts were detected while syncing from upstream.\n\n"
    body += "## Upstream Repository\n"
    body += "- **Repository:** " + upstream_repo + "\n"
    body += "- **Branch:** " + upstream_branch + "\n\n"

    body += "## Conflicted Files\n"
    body += "```\n" + join(conflicts, "\n") + "\n```\n\n"

    body += "## Resolution Steps\n"
    body += "1. Manually fetch and merge upstream changes\n"
    body += "2. Resolve conflicts in the listed files\n"
    body += "3. Create a pull request with resolved changes\n"
    body += "4. Close this issue once resolved\n\n"

    body += "## Commands for manual resolution:\n"
    body += "```bash\n"
    body += "git remote add upstream https://github.com/" + upstream_repo + ".git\n"
    body += "git fetch upstream\n"
    body += "git checkout -b resolve-upstream-conflicts\n"
    body += "git merge upstream/" + upstream_branch + "\n"
    body += "# Resolve conflicts manually\n"
    body += "git add .\n"
    body += "git commit\n"
    body += "git push origin resolve-upstream-conflicts\n"
    body += "```\n\n"
    body += "---\n"
    body += "*This issue was automatically created by the upstream sync workflow.*\n"

    RETURN body
```

## Comprehensive Summary

```
FUNCTION create_sync_summary():
    summary = build_sync_summary_report()
    write_github_step_summary(summary)
```

```
FUNCTION build_sync_summary_report():
    summary = "# Upstream Sync Summary\n\n"

    IF NOT upstream_configured:
        summary += "⚠️ No upstream repository configured\n"
        RETURN summary

    summary += "**Upstream:** " + upstream_repo + "\n"
    summary += "**Branch:** " + upstream_branch + "\n\n"

    IF has_changes:
        summary += "**Status:** Changes detected\n"
        summary += "- Behind by: " + commits_behind + " commits\n"
        summary += "- Ahead by: " + commits_ahead + " commits\n\n"

        IF merge_successful:
            summary += "✅ Successfully created sync pull request\n"
        ELSE:
            summary += "⚠️ Merge conflicts detected - manual resolution required\n"
    ELSE:
        summary += "**Status:** Already up to date with upstream\n"

    RETURN summary
```

## Key Implementation Notes

- **Flexible Configuration**: Supports both environment defaults and manual input for upstream repository
- **Remote Management**: Automatically manages upstream remote configuration
- **Change Analysis**: Compares commit counts to determine sync necessity
- **Conflict Handling**: Creates detailed issues with resolution instructions for conflicts
- **Subrepo Integration**: Automatically identifies which subrepos will be affected by upstream changes
- **Force Option**: Allows forced sync even when no changes detected

## State Management

- **Remote State**: Manages upstream remote configuration dynamically
- **Branch State**: Creates unique timestamped branches for each sync operation
- **Merge State**: Handles both successful merges and conflict scenarios
- **Change State**: Tracks what changes will affect which subrepos

## Integration Patterns

- **Automatic Distribution**: Relies on push-subrepos workflow for downstream synchronization
- **Conflict Resolution**: Creates issues with detailed instructions for manual resolution
- **Scheduled Execution**: Designed for daily automated upstream synchronization
- **Manual Override**: Supports force sync and custom upstream/branch specification

## Error Recovery

- **Merge Conflicts**: Aborts failed merges and creates resolution issues
- **Remote Access**: Handles cases where upstream repository is inaccessible
- **Configuration Missing**: Gracefully handles missing upstream configuration
- **State Cleanup**: Ensures clean state even when operations fail