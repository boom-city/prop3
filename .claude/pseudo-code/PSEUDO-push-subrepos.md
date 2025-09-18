# Push to Subrepos Workflow - Pseudo Code

## Workflow Triggers
- **Push events** to main/master (excludes workflow files, docs, README.md)
- **Manual dispatch** with optional commit_range parameter

## Main Algorithm Flow

```
FUNCTION push_subrepos_workflow():
    change_detection = detect_changed_subrepos()

    IF change_detection.has_changes:
        PARALLEL_EXECUTE push_changes_to_subrepos(change_detection.changed_subrepos)

    generate_sync_summary(change_detection)
```

## Change Detection Logic

```
FUNCTION detect_changed_subrepos():
    checkout_repository(fetch_depth=0)
    setup_git_configuration()

    commit_range = determine_commit_range()
    changed_files = get_changed_files(commit_range)

    changed_subrepos = map_files_to_subrepos(changed_files)

    RETURN {
        changed_subrepos: changed_subrepos,
        has_changes: (changed_subrepos.length > 0)
    }
```

```
FUNCTION determine_commit_range():
    IF manual_dispatch AND input.commit_range:
        RETURN input.commit_range
    ELIF push_event:
        IF github.event.before == "0000000000000000000000000000000000000000":
            RETURN github.sha  # Initial commit
        ELSE:
            RETURN github.event.before + ".." + github.sha
    ELSE:
        RETURN "HEAD~1..HEAD"  # Default fallback
```

```
FUNCTION map_files_to_subrepos(changed_files):
    config = load_subrepo_configuration()
    unique_subrepos = []

    FOR EACH file IN changed_files:
        FOR EACH subrepo IN config.subrepos:
            IF file.startswith(subrepo.prefix + "/") OR file == subrepo.prefix:
                add_unique(unique_subrepos, subrepo)
                BREAK  # Found matching subrepo for this file

    RETURN unique_subrepos
```

## Parallel Push Strategy

```
FUNCTION push_changes_to_subrepos(changed_subrepos):
    STRATEGY:
        matrix: changed_subrepos
        max_parallel: 10
        fail_fast: false

    FOR EACH subrepo IN changed_subrepos PARALLEL:
        push_single_subrepo(subrepo)
```

## Individual Subrepo Push Process

```
FUNCTION push_single_subrepo(subrepo):
    checkout_repository(fetch_depth=0)
    setup_git_configuration()

    repo_info = parse_subrepo_details(subrepo)

    ensure_remote_repository_exists(repo_info)
    sync_to_remote_repository(repo_info)
```

```
FUNCTION parse_subrepo_details(subrepo):
    RETURN {
        prefix: subrepo.prefix,
        remote: subrepo.remote,
        branch: subrepo.branch,
        repo_name: extract_repo_name(subrepo.remote),
        repo_owner: extract_repo_owner(subrepo.remote)
    }
```

```
FUNCTION ensure_remote_repository_exists(repo_info):
    IF NOT github_repo_exists(repo_info.repo_owner, repo_info.repo_name):
        github_create_repository(
            owner=repo_info.repo_owner,
            name=repo_info.repo_name,
            visibility="private",
            description="Subrepo for " + repo_info.prefix
        )
```

## Repository Synchronization

```
FUNCTION sync_to_remote_repository(repo_info):
    temp_repo = create_temp_directory()

    TRY:
        # Try cloning existing repository
        clone_repository(repo_info.remote, temp_repo)
        change_directory(temp_repo)
        checkout_branch(repo_info.branch)
    CATCH clone_error:
        # Initialize new repository
        initialize_git_repository(temp_repo)
        change_directory(temp_repo)
        create_branch(repo_info.branch)
        add_remote("origin", repo_info.remote)

    sync_files_from_monorepo(repo_info.prefix, temp_repo)
    commit_and_push_changes(repo_info, temp_repo)
    cleanup_temp_directory(temp_repo)
```

```
FUNCTION sync_files_from_monorepo(prefix, temp_repo):
    IF NOT directory_exists(prefix):
        THROW error("Source directory does not exist: " + prefix)

    # Clear existing files (preserve .git)
    clear_directory_except_git(temp_repo)

    # Copy all files from monorepo prefix
    copy_files(prefix + "/*", temp_repo)
    copy_hidden_files(prefix + "/.[^.]*", temp_repo)  # Copy .files but not . or ..
```

```
FUNCTION commit_and_push_changes(repo_info, temp_repo):
    change_directory(temp_repo)
    git_add_all()

    IF git_has_changes():
        # Get original commit message from monorepo
        original_commit_message = get_last_commit_message(monorepo_workspace)

        full_commit_message = original_commit_message +
                             "\n\nSynced from monorepo: " + github.repository +
                             "@" + github.sha

        git_commit(full_commit_message)

        TRY:
            git_push("origin", repo_info.branch, force=true)
            log_success("Successfully pushed changes to " + repo_info.remote)
        CATCH push_error:
            THROW error("Failed to push changes")
    ELSE:
        log_info("No changes to push for " + repo_info.prefix)
```

## Summary Generation

```
FUNCTION generate_sync_summary(change_detection, push_results):
    summary = {
        commit: github.sha,
        author: github.actor,
        timestamp: current_time,
        has_changes: change_detection.has_changes,
        changed_subrepos: change_detection.changed_subrepos
    }

    create_github_step_summary(summary)
```

## Error Handling and Logging

```
FUNCTION handle_push_errors():
    FOR EACH job IN parallel_push_jobs:
        IF job.status == "failure":
            log_error("Failed to sync: " + job.subrepo.prefix)
        ELSE:
            log_success("Successfully synced: " + job.subrepo.prefix)
```

## Key Implementation Notes

- **Selective Processing**: Only processes subrepos with actual file changes
- **Parallel Execution**: Up to 10 concurrent repository syncs
- **Force Push**: Uses force push to handle history divergence
- **Repository Creation**: Auto-creates missing GitHub repositories
- **File Synchronization**: Complete file sync (not git subtree operations)
- **Commit Preservation**: Includes original monorepo commit messages
- **Error Isolation**: Individual subrepo failures don't stop other syncs

## State Management

- **Change Detection**: Maps file changes to specific subrepos
- **Repository State**: Handles both existing and new repositories
- **Branch Management**: Creates target branch if it doesn't exist
- **Content Sync**: Overwrites entire subrepo content with monorepo content
- **History**: Preserves reference to original monorepo commits

## Critical Patterns

- **Path Filtering**: Excludes workflow files and documentation from triggering syncs
- **Commit Range**: Handles initial commits and regular pushes differently
- **Cleanup**: Always removes temporary directories regardless of success/failure
- **Authentication**: Uses enhanced token (GH_PAT) for repository operations