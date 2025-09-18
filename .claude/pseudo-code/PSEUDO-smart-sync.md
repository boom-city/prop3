# Smart Sync - Auto-detect and Bootstrap Workflow - Pseudo Code

## Workflow Triggers
- **Push events** to main/master (excludes workflow files, scripts, docs, .claude)

## Main Algorithm Flow

```
FUNCTION smart_sync_workflow():
    analysis = analyze_changes_and_determine_actions()

    IF analysis.needs_bootstrap:
        auto_bootstrap_new_repositories(analysis.new_repositories)

    IF analysis.has_resource_changes OR bootstrap_successful:
        sync_repositories = prepare_sync_list(analysis)
        PARALLEL_EXECUTE sync_changes_to_subrepos(sync_repositories)

    generate_smart_sync_summary(analysis)
```

## Comprehensive Change Analysis

```
FUNCTION analyze_changes_and_determine_actions():
    checkout_repository(fetch_depth=2)

    commit_range = determine_commit_range()
    changed_files = get_changed_files(commit_range)

    INITIALIZE analysis_flags:
        has_resource_changes = false
        has_config_changes = false
        needs_bootstrap = false

    # Analyze configuration changes
    IF changed_files.contains(".github/subrepo-config.json"):
        has_config_changes = true
        needs_bootstrap = true

    # Analyze resource changes
    IF changed_files.any_starts_with("resources/"):
        has_resource_changes = true

    # Detect missing git initialization
    missing_git_repositories = check_for_missing_git_initialization()
    IF missing_git_repositories.length > 0:
        needs_bootstrap = true

    # Detect new repositories from config changes
    new_repositories = detect_new_repositories_from_config()

    # Merge missing and new repositories
    final_new_repositories = merge_repository_lists(missing_git_repositories, new_repositories)

    # Detect changed subrepos
    changed_subrepos = map_resource_changes_to_subrepos(changed_files)

    RETURN {
        has_resource_changes: has_resource_changes,
        has_config_changes: has_config_changes,
        needs_bootstrap: needs_bootstrap,
        new_repositories: final_new_repositories,
        changed_subrepos: changed_subrepos
    }
```

## Missing Git Initialization Detection

```
FUNCTION check_for_missing_git_initialization():
    config = load_subrepo_configuration()
    missing_repos = []

    FOR EACH subrepo IN config.subrepos:
        IF directory_exists(subrepo.prefix) AND has_content(subrepo.prefix):
            IF NOT directory_exists(subrepo.prefix + "/.git"):
                missing_repos.add(subrepo)
        ELIF NOT directory_exists(subrepo.prefix):
            missing_repos.add(subrepo)

    RETURN missing_repos
```

## New Repository Detection

```
FUNCTION detect_new_repositories_from_config():
    IF NOT has_config_changes:
        RETURN []

    current_prefixes = get_current_prefixes()

    TRY:
        previous_config = git_show("HEAD~1:.github/subrepo-config.json")
        previous_prefixes = extract_prefixes(previous_config)

        new_prefixes = difference(current_prefixes, previous_prefixes)
        RETURN get_configs_for_prefixes(new_prefixes)
    CATCH no_previous_config:
        # First time configuration - all repositories are new
        RETURN load_all_subrepo_configs()
```

## Auto-Bootstrap Process

```
FUNCTION auto_bootstrap_new_repositories(new_repositories):
    setup_git_user("GitHub Actions [Smart-Sync]")

    IF new_repositories.length > 0:
        create_remote_repositories(new_repositories)
        initialize_local_directories(new_repositories)
        commit_new_directory_structure()
```

```
FUNCTION create_remote_repositories(repositories):
    FOR EACH repo IN repositories:
        repo_info = parse_repository_url(repo.remote)

        IF NOT github_repo_exists(repo_info.owner, repo_info.name):
            TRY:
                github_create_repository(
                    owner=repo_info.owner,
                    name=repo_info.name,
                    visibility="private",
                    description="Auto-created subrepo for " + repo.prefix
                )
            CATCH creation_error:
                log_warning("Failed to create: " + repo_info.full_name)
```

```
FUNCTION initialize_local_directories(repositories):
    FOR EACH repo IN repositories:
        IF NOT directory_exists(repo.prefix) OR is_empty(repo.prefix):
            create_directory(repo.prefix)
            write_file(repo.prefix + "/README.md", "# " + repo.prefix)
            log_success("Initialized: " + repo.prefix)
```

## Sync Preparation Logic

```
FUNCTION prepare_sync_list(analysis):
    repositories_to_sync = []

    # Add changed repositories
    IF analysis.changed_subrepos.length > 0:
        repositories_to_sync.add_all(analysis.changed_subrepos)

    # Add new repositories
    IF analysis.new_repositories.length > 0:
        repositories_to_sync.add_all(analysis.new_repositories)

    # Remove duplicates by prefix
    repositories_to_sync = unique_by_prefix(repositories_to_sync)

    RETURN {
        repositories_to_sync: repositories_to_sync,
        has_repositories: (repositories_to_sync.length > 0)
    }
```

## Parallel Repository Synchronization

```
FUNCTION sync_changes_to_subrepos(repositories):
    STRATEGY:
        matrix: repositories
        max_parallel: 10
        fail_fast: false

    FOR EACH repo IN repositories PARALLEL:
        sync_single_repository(repo)
```

```
FUNCTION sync_single_repository(repo):
    checkout_repository(fetch_depth=0)
    setup_git_user("GitHub Actions [Smart-Sync]")

    repo_info = parse_subrepo_details(repo)
    sync_to_remote_repository(repo_info)
```

## Advanced Repository Sync

```
FUNCTION sync_to_remote_repository(repo_info):
    IF NOT directory_exists(repo_info.prefix):
        THROW error("Source directory does not exist: " + repo_info.prefix)

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

    sync_content_from_monorepo(repo_info.prefix, temp_repo)
    commit_and_push_with_lease(repo_info, temp_repo)
    cleanup_temp_directory(temp_repo)
```

```
FUNCTION commit_and_push_with_lease(repo_info, temp_repo):
    change_directory(temp_repo)
    git_add_all()

    IF git_has_changes():
        original_commit = get_last_commit_message(monorepo_workspace)

        sync_commit_message = original_commit +
                             "\n\n🔄 Synced from monorepo: " + github.repository +
                             "@" + github.sha

        git_commit(sync_commit_message)

        TRY:
            git_push_force_with_lease("origin", repo_info.branch)
            log_success("Successfully synced " + repo_info.prefix)
        CATCH push_error:
            THROW error("Failed to push changes")
    ELSE:
        log_info("No changes to sync for " + repo_info.prefix)
```

## Comprehensive Summary Generation

```
FUNCTION generate_smart_sync_summary(analysis, bootstrap_results, sync_results):
    summary = {
        commit: github.sha,
        author: github.actor,
        timestamp: current_time,
        analysis_results: {
            resource_changes: analysis.has_resource_changes,
            config_changes: analysis.has_config_changes,
            bootstrap_needed: analysis.needs_bootstrap
        },
        new_repositories: analysis.new_repositories,
        changed_repositories: analysis.changed_subrepos,
        bootstrap_status: bootstrap_results.status,
        sync_status: sync_results.status
    }

    create_detailed_github_summary(summary)
```

```
FUNCTION create_detailed_github_summary(summary):
    output = "# 🔄 Smart-Sync Summary\n\n"
    output += "**Commit:** " + summary.commit + "\n"
    output += "**Author:** " + summary.author + "\n"
    output += "**Time:** " + summary.timestamp + "\n\n"

    output += "## 📊 Analysis Results\n"
    output += "- **Resource changes:** " + summary.analysis_results.resource_changes + "\n"
    output += "- **Config changes:** " + summary.analysis_results.config_changes + "\n"
    output += "- **Bootstrap needed:** " + summary.analysis_results.bootstrap_needed + "\n\n"

    IF summary.new_repositories.length > 0:
        output += "## 🆕 New Repositories\n"
        output += "Automatically created and initialized:\n"
        output += format_json(summary.new_repositories) + "\n\n"

    IF summary.changed_repositories.length > 0:
        output += "## 📝 Updated Repositories\n"
        output += "Synced changes to existing repositories:\n"
        output += format_json(summary.changed_repositories) + "\n\n"

    output += "## ✅ Status\n"
    output += "- **Bootstrap:** " + summary.bootstrap_status + "\n"
    output += "- **Sync:** " + summary.sync_status + "\n"

    write_github_step_summary(output)
```

## Key Implementation Notes

- **Intelligent Detection**: Combines multiple detection methods (config changes, missing dirs, resource changes)
- **Auto-Creation**: Creates both GitHub repositories and local directory structures
- **Force-with-Lease**: Uses safer force push strategy to prevent data loss
- **Comprehensive Analysis**: Checks git initialization state, not just directory existence
- **JSON Validation**: Validates all JSON outputs before setting workflow outputs
- **Merge Logic**: Intelligently merges repository lists from different detection sources

## State Management Patterns

- **Multi-State Detection**: Handles missing directories, missing .git, and new configs
- **Repository Creation**: Auto-creates GitHub repositories for new configurations
- **Directory Initialization**: Creates basic directory structure with README files
- **Sync Coordination**: Coordinates between bootstrap and sync operations
- **Change Propagation**: Ensures changes flow from analysis → bootstrap → sync

## Advanced Features

- **Differential Config Analysis**: Compares current vs. previous configuration versions
- **Missing Git Detection**: Identifies directories that need git initialization
- **Repository Merging**: Combines multiple repository lists while removing duplicates
- **Conditional Execution**: Each stage only runs when actually needed
- **Status Propagation**: Passes results between jobs for coordinated execution