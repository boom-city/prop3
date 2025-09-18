# Boom Base - Multi-Repository Management System

## Project Overview
GitHub Actions automation system managing 360+ FiveM resource repositories through a centralized monorepo structure with automated synchronization, state handling, and conflict resolution.

## Tech Stack
- **Platform**: GitHub Actions (CI/CD)
- **Languages**: Bash scripting, YAML workflows
- **VCS**: Git with subtree pattern for mono-repo to multi-subrepo architecture
- **Configuration**: JSON-based repository mapping
- **Target Resources**: FiveM/QBCore/ESX framework components
- **History Management**: Git subtree for commit history splitting and preservation

## Project Structure
- `.github/workflows/`: Core automation workflows (push, pull, bootstrap, sync, conflict resolution)
- `.github/subrepo-config.json`: Central repository mapping configuration
- `.claude/dev-docs/`: Technical documentation for operations and development
- `resources/`: Managed FiveM resources organized by category
  - `[qbx]`, `[ox]`, `[mri]`: Framework components
  - `[boom-scripts]`, `[boom-veiculos]`: Custom resources
  - `[addons]`, `[standalone]`: Independent resources

## Commands
- **Manual sync**: `gh workflow run pull-subrepos.yml`
- **Force push**: `gh workflow run push-subrepos.yml`
- **Bootstrap**: `gh workflow run bootstrap.yml`
- **Health check**: `gh workflow run health-check.yml`
- **Delete repos**: `gh workflow run delete-repositories.yml --field repositories="repo1,repo2" --field confirm_deletion="DELETE"`
- **Validate config**: `jq empty .github/subrepo-config.json`
- **Check state**: `find resources -name ".git" -type d | wc -l`

### Git Subtree Operations
- **Push subtree**: `git subtree push --prefix=resources/[category]/resource-name origin main`
- **Pull subtree**: `git subtree pull --prefix=resources/[category]/resource-name origin main --squash`
- **Add subtree**: `git subtree add --prefix=resources/[category]/resource-name origin main --squash`
- **Split subtree**: `git subtree split --prefix=resources/[category]/resource-name -b split-branch`
- **History preservation**: Subtree operations maintain commit history across repositories

## Workflow Guidelines
- **Multi-stage state handling**: System automatically detects and handles 6 different repository states
- **Push changes**: Commits to main trigger automatic subrepo detection and synchronization via git subtree
- **Pull changes**: Scheduled and manual sync from all subrepos using git subtree pull operations
- **Conflict resolution**: Creates PRs for manual review when conflicts detected during subtree operations
- **Repository lifecycle**: Auto-creates missing remotes, initializes local git as needed
- **History preservation**: Git subtree maintains complete commit history when splitting/merging repositories
- **Subtree automation**: GitHub Actions use git subtree commands for seamless mono-repo to multi-repo workflows

## Code Style & Conventions
- **Repository naming**: Use lowercase with hyphens (e.g., `my-new-script`)
- **Categories**: Place resources in appropriate brackets (`[boom-scripts]`, `[addons]`, etc.)
- **Configuration updates**: Always validate JSON before committing
- **Commit messages**: Be descriptive, reference issues when applicable

## CRITICAL REQUIREMENTS - MUST BE FOLLOWED ALWAYS

### ⚠️ MANDATORY State Management Rules
- **NEVER** manually manipulate `.git` directories in resources folders
- **NEVER** bypass the workflow system for repository operations
- **ALWAYS** update `subrepo-config.json` before adding/removing resources
- **ALWAYS** wait for workflows to complete before making conflicting changes

### ⚠️ MANDATORY Security Requirements
- **NEVER** commit GitHub tokens or secrets to any repository
- **NEVER** grant excessive permissions to workflow tokens
- **ALWAYS** use minimal required permissions for operations
- **MONITOR** API rate limits to prevent service disruption

### ⚠️ DO NOT - Dangerous Operations
- **DO NOT** disable workflows without emergency procedures
- **DO NOT** force push to subrepos directly - use workflows
- **DO NOT** delete remote repositories without backup verification
- **DO NOT** modify workflow files without testing in dry-run mode

### ⚠️ Performance Constraints
- **Rate limiting**: System implements intelligent backoff for GitHub API
- **Batch operations**: Maximum 50 repositories per workflow run
- **Sync frequency**: Pull workflows run every 4 hours by default
- **Timeout limits**: Workflows timeout after 6 hours

### ⚠️ Legacy Patterns
- **Subtree pattern**: Uses git subtree commands, NOT git submodules - do not use submodule commands
- **Configuration format**: Must maintain backward compatibility with existing JSON structure
- **Workflow triggers**: Preserve existing trigger patterns for team consistency
- **History handling**: Git subtree preserves commit history unlike traditional subrepo patterns

## Emergency Procedures
```bash
# EMERGENCY SHUTDOWN
gh workflow disable push-subrepos.yml
gh workflow disable pull-subrepos.yml
gh issue create --title "🚨 EMERGENCY: Automation Shutdown" --label "emergency"

# RECOVERY
./scripts/state-inspection.sh
./scripts/validate-config.sh
gh workflow run sync-state.yml --field dry_run=true
# If successful, re-enable workflows
```

## Monitoring & Maintenance
- **Daily**: Check workflow failures with `gh run list --status=failure`
- **Weekly**: Audit configuration for orphaned repositories
- **Monthly**: Full system sync and backup verification
- **Critical alerts**: Workflow failure rate > 10%, API usage > 80%