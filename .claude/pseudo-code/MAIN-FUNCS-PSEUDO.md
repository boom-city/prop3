## Missing Git Initialization Detection

```
FUNCTION check_for_missing_git_initialization():
    config = load_subrepo_configuration()
    missing_repos = []

    FOR EACH subrepo IN config.subrepos:
        IF directory_exists(subrepo.prefix) AND has_git_folder(subrepo.prefix): <!-- ## Checks for .git folder or run git status on the folder to validate that a git repo is initialized. -->
            IF NOT directory_exists(subrepo.prefix + "/.git"):
                missing_repos.add(subrepo)
        ELIF NOT directory_exists(subrepo.prefix):
            missing_repos.add(subrepo)
    RETURN missing_repos
```

## Missing Remote Repo Detection

```
FUNCTION check_for_missing_remote_repos():
    remote_list = gh repo list boom-city
    FOR EACH config.subrepo 
        IF config.subrepo NOT IN remote_list
            gh repo create boom-city/config.subrepo.remotename
    RETURN missing_remotes
```

## Creation of missing Remote Repo

```
FUNCTION create_remote_repos():
    missing_remotes = check_for_missing_remote_repos()
    FOR EACH remote in missing_remotes: 
        gh repo create boom-city/remote --private
        gh label create automated -R boom-city/remote --color 0000FF --description "Label for GitHub Actions"
```
