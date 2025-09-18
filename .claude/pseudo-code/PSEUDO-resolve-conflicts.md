# Resolve Subrepo Conflicts Workflow - Pseudo Code

## Workflow Triggers
- **Manual dispatch** with conflict_type, subrepo_prefix, and strategy parameters
- **Repository dispatch** with 'resolve-conflict' type (triggered by other workflows)

## Main Algorithm Flow

```
FUNCTION resolve_conflicts_workflow():
    conflict_analysis = detect_and_analyze_conflicts()

    IF conflict_analysis.has_conflicts:
        resolution_results = resolve_detected_conflicts(conflict_analysis)

        IF resolution_strategy == "manual":
            create_manual_review_checklist(conflict_analysis)
```

## Conflict Detection and Analysis

```
FUNCTION detect_and_analyze_conflicts():
    checkout_repository(fetch_depth=0)
    setup_git_configuration()

    conflict_detection_script = create_conflict_detection_script()
    conflict_results = execute_conflict_detection(conflict_detection_script)

    RETURN {
        has_conflicts: conflict_results.conflict_count > 0,
        conflict_details: conflict_results.conflict_report
    }
```

## Detailed Conflict Detection Logic

```
FUNCTION create_conflict_detection_script():
    config = load_subrepo_configuration()
    filter = input.subrepo_prefix
    conflict_report = initialize_conflict_report()

    FOR EACH subrepo IN config.subrepos:
        IF should_check_subrepo(subrepo, filter):
            check_subrepo_conflicts(subrepo, conflict_report)

    RETURN conflict_report
```

```
FUNCTION check_subrepo_conflicts(prefix, remote, branch, conflict_report):
    # Skip if filter doesn't match
    IF filter_set AND NOT prefix.contains(filter):
        RETURN skip

    temp_dir = create_temp_directory()

    TRY:
        clone_repository(remote, branch, temp_dir)
    CATCH clone_error:
        log_warning("Cannot access remote: " + remote)
        cleanup_temp_directory(temp_dir)
        RETURN skip

    conflict_analysis = compare_local_and_remote_files(prefix, temp_dir)

    IF conflict_analysis.has_conflicts:
        add_to_conflict_report(conflict_report, {
            prefix: prefix,
            remote: remote,
            files: conflict_analysis.conflicted_files,
            conflict_type: "content"
        })

    cleanup_temp_directory(temp_dir)
```

## File Comparison and Conflict Detection

```
FUNCTION compare_local_and_remote_files(prefix, temp_dir):
    change_directory(temp_dir)
    local_files = get_files_list(monorepo_workspace + "/" + prefix)
    remote_files = get_files_list(temp_dir)

    conflicted_files = []

    FOR EACH file IN remote_files:
        local_file_path = monorepo_workspace + "/" + prefix + "/" + file
        remote_file_path = temp_dir + "/" + file

        IF file_exists(local_file_path) AND file_exists(remote_file_path):
            IF NOT files_are_identical(local_file_path, remote_file_path):
                conflicted_files.add(file)

    RETURN {
        has_conflicts: (conflicted_files.length > 0),
        conflicted_files: conflicted_files
    }
```

## Conflict Resolution Process

```
FUNCTION resolve_detected_conflicts(conflict_details):
    create_resolution_branch()
    apply_resolution_strategy(conflict_details)
    commit_resolution_changes()
    push_resolution_branch()
    create_resolution_pull_request(conflict_details)
```

```
FUNCTION create_resolution_branch():
    resolution_branch = "resolve-conflicts-" + timestamp()
    git_checkout_new_branch(resolution_branch)
    RETURN resolution_branch
```

## Resolution Strategy Implementation

```
FUNCTION apply_resolution_strategy(conflict_details):
    strategy = input.strategy
    conflicts = conflict_details.conflicts

    FOR EACH conflict IN conflicts:
        resolve_single_subrepo_conflict(conflict, strategy)
```

```
FUNCTION resolve_single_subrepo_conflict(conflict, strategy):
    prefix = conflict.prefix
    remote = conflict.remote

    temp_dir = create_temp_directory()
    clone_repository(remote, temp_dir)

    SWITCH strategy:
        CASE "ours":
            apply_ours_strategy(prefix)
        CASE "theirs":
            apply_theirs_strategy(prefix, temp_dir)
        CASE "manual":
            apply_manual_strategy(prefix, temp_dir)

    cleanup_temp_directory(temp_dir)
```

## Strategy-Specific Resolution

```
FUNCTION apply_ours_strategy(prefix):
    # Keep local version - no action needed
    log_success("Kept local version for: " + prefix)
```

```
FUNCTION apply_theirs_strategy(prefix, temp_dir):
    # Take remote version
    rsync_with_delete(
        source=temp_dir + "/",
        target=prefix + "/",
        exclude=[".git"]
    )
    log_success("Took remote version for: " + prefix)
```

```
FUNCTION apply_manual_strategy(prefix, temp_dir):
    # Create conflict markers for manual resolution
    change_directory(temp_dir)

    FOR EACH file IN get_all_files(exclude_git=true):
        local_file = monorepo_workspace + "/" + prefix + "/" + file
        remote_file = temp_dir + "/" + file

        IF file_exists(local_file) AND file_exists(remote_file):
            IF NOT files_are_identical(local_file, remote_file):
                create_conflict_marker_file(local_file, remote_file, prefix, remote)

    log_info("Manual resolution needed for: " + prefix)
```

```
FUNCTION create_conflict_marker_file(local_file, remote_file, prefix, remote):
    conflict_file = local_file + ".conflict"

    conflict_content = "<<<<<<< LOCAL (monorepo)\n"
    conflict_content += read_file(local_file)
    conflict_content += "\n=======\n"
    conflict_content += read_file(remote_file)
    conflict_content += "\n>>>>>>> REMOTE (subrepo: " + remote + ")\n"

    write_file(conflict_file, conflict_content)
```

## Resolution Commit and Pull Request

```
FUNCTION commit_resolution_changes():
    IF git_has_changes():
        git_add_all()

        commit_message = build_resolution_commit_message()
        git_commit(commit_message + "\n[skip ci]")
    ELSE:
        log_info("No changes to commit after resolution")
```

```
FUNCTION build_resolution_commit_message():
    base_message = "resolve: Apply " + input.strategy + " strategy for conflicts"

    full_message = base_message +
                  "\n\nResolution type: " + input.conflict_type +
                  "\nStrategy: " + input.strategy +
                  "\nTriggered by: " + github.actor

    RETURN full_message
```

```
FUNCTION create_resolution_pull_request(conflict_details):
    pr_body = build_resolution_pr_body(conflict_details)

    github_create_pull_request(
        title="🔧 Resolve conflicts: " + input.strategy + " strategy",
        body=pr_body,
        base="main",
        head=resolution_branch,
        labels=["conflict-resolution", "automated"]
    )
```

## Detailed Pull Request Body

```
FUNCTION build_resolution_pr_body(conflict_details):
    body = "## 🔧 Conflict Resolution\n\n"
    body += "This PR resolves conflicts detected between the monorepo and subrepos.\n\n"
    body += "### Resolution Details\n"
    body += "- **Type:** " + input.conflict_type + "\n"
    body += "- **Strategy:** " + input.strategy + "\n"
    body += "- **Triggered by:** " + github.actor + "\n"
    body += "- **Time:** " + current_timestamp() + "\n\n"

    body += "### Conflicts Resolved\n"
    FOR EACH conflict IN conflict_details.conflicts:
        body += "- **" + conflict.prefix + "**: " + conflict.files.length + " files\n"

    body += "\n### Resolution Strategy\n"
    SWITCH input.strategy:
        CASE "ours":
            body += "✅ **Kept local (monorepo) version** - All conflicts resolved by keeping the monorepo version.\n"
        CASE "theirs":
            body += "✅ **Took remote (subrepo) version** - All conflicts resolved by taking the subrepo version.\n"
        CASE "manual":
            body += "⚠️ **Manual resolution required** - Conflict markers have been added to affected files. Please review and resolve manually.\n"

    body += "\n### Next Steps\n"
    body += "1. Review the changes in this PR\n"
    body += "2. Verify the resolution is correct\n"
    body += "3. Merge to apply the resolution\n"
    body += "4. Changes will be synced to subrepos automatically\n\n"
    body += "---\n"
    body += "*This PR was automatically generated by the conflict resolution workflow.*\n"

    RETURN body
```

## Manual Review Process

```
FUNCTION create_manual_review_checklist(conflict_details):
    IF input.strategy == "manual":
        issue_body = build_manual_review_issue_body(conflict_details)

        github_create_issue(
            title="📋 Manual conflict resolution required",
            body=issue_body,
            labels=["conflict-resolution", "manual-review"],
            assignee=github.actor
        )
```

```
FUNCTION build_manual_review_issue_body(conflict_details):
    body = "Manual conflict resolution is required for the following subrepos:\n\n"
    body += "## Conflicts Requiring Resolution\n\n"

    FOR EACH conflict IN conflict_details.conflicts:
        body += "- [ ] **" + conflict.prefix + "**\n"
        body += "  - Remote: " + conflict.remote + "\n"
        body += "  - Files: " + join(conflict.files, ", ") + "\n\n"

    body += "## Resolution Instructions\n\n"
    body += "1. Check out the resolution branch created by this workflow\n"
    body += "2. Look for `.conflict` files in the affected directories\n"
    body += "3. Resolve each conflict manually\n"
    body += "4. Delete the `.conflict` files after resolution\n"
    body += "5. Commit your changes\n"
    body += "6. Mark items as complete in this checklist\n\n"

    body += "## Useful Commands\n\n"
    body += "```bash\n"
    body += "# Find all conflict files\n"
    body += "find . -name '*.conflict' -type f\n\n"
    body += "# View a conflict file\n"
    body += "cat path/to/file.conflict\n\n"
    body += "# After resolving, remove conflict file\n"
    body += "rm path/to/file.conflict\n"
    body += "```\n\n"
    body += "---\n"
    body += "*This issue was automatically created by the conflict resolution workflow.*\n"

    RETURN body
```

## Key Implementation Notes

- **Multi-Strategy Support**: Implements "ours", "theirs", and "manual" resolution strategies
- **Conflict Detection**: Compares file content between local and remote repositories
- **Branch Management**: Creates unique timestamped branches for each resolution
- **Manual Workflow**: Creates conflict marker files for human review
- **Integration**: Creates pull requests for automatic conflict resolution
- **Issue Tracking**: Creates GitHub issues for manual resolution tasks

## State Management

- **Conflict State**: Tracks which files have conflicts in each subrepo
- **Resolution State**: Maintains resolution progress and strategy application
- **Branch State**: Creates isolated branches for conflict resolution work
- **Review State**: Provides checklists and tracking for manual resolutions

## Error Handling Patterns

- **Remote Access**: Gracefully handles inaccessible remote repositories
- **File Comparison**: Robust file difference detection and conflict identification
- **Strategy Validation**: Ensures selected strategy is properly applied
- **Cleanup**: Always removes temporary directories regardless of outcome

## Workflow Integration

- **Trigger Integration**: Can be called by other workflows when conflicts detected
- **PR Integration**: Creates pull requests that integrate with normal review process
- **Issue Integration**: Creates issues for tracking manual resolution progress
- **CI Coordination**: Uses `[skip ci]` to prevent recursive workflow triggering