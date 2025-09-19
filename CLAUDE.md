# Boom Base - Multi-Repository Management System

## Project Overview
GitHub Actions automation system managing 360+ FiveM resource repositories through a centralized monorepo structure with automated synchronization, state handling, and conflict resolution.

## Reference Patterns
- `.claude/dev-docs/pseudo-code/*` 

## Tech Stack
- **Platform**: GitHub Actions (CI/CD)
- **Languages**: YAML workflows
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
- **Validate config**: `jq empty .github/subrepo-config.json`

### Git Subtree Operations
- **Push subtree**: `git subtree push --prefix=resources/[category]/resource-name origin main`
- **Pull subtree**: `git subtree pull --prefix=resources/[category]/resource-name origin main --squash`
- **Add subtree**: `git subtree add --prefix=resources/[category]/resource-name origin main --squash`
- **Split subtree**: `git subtree split --prefix=resources/[category]/resource-name -b split-branch`
- **History preservation**: Subtree operations maintain commit history across repositories

## Workflow Guidelines
- **Multi-stage state handling**: System automatically detects and handles 6 different repository states
- **Push changes**: Commits to main trigger automatic subrepo detection and synchronization via git subtree
- **Pull changes**: Pull to the main trigger automatic pull sync from all subrepos using git subtree pull operations
- **Conflict resolution**: Creates PRs for manual review when conflicts detected during subtree operations
- **Repository lifecycle**: Auto-creates missing remotes, initializes local git as needed
- **History preservation**: Git subtree maintains complete commit history when splitting/merging repositories
- **Subtree automation**: GitHub Actions use git subtree commands for seamless mono-repo to multi-repo workflows

## Code Style & Conventions
- **Repository naming**: Use lowercase with hyphens (e.g., `my-new-script`)
- **Categories**: Place resources in appropriate brackets (`[boom-scripts]`, `[addons]`, etc.)
- **Categories paths**: Always look at the paths on `subrepo-config.json` file
- **Configuration updates**: Always validate JSON before committing
- **Commit messages**: Be objective, short, reference issues when applicable.

## CRITICAL REQUIREMENTS - MUST BE FOLLOWED ALWAYS

### ⚠️ MANDATORY State Management Rules
- **NEVER** manually manipulate `.git` directories in resources folders
- **NEVER** bypass the workflow system for repository operations
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