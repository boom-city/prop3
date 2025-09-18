# System Overview

## Architecture

GitHub Actions automation managing 360+ repositories using git subtree for mono-repo to multi-subrepo architecture:
- `[qbx]`, `[ox]`, `[mri]` - Framework components
- `[boom-scripts]`, `[boom-veiculos]` - Custom resources
- `[addons]`, `[standalone]` - Independent resources

### Git Subtree Integration
- **History Preservation**: Complete commit history maintained across repository splits
- **Seamless Synchronization**: Automated subtree push/pull operations via GitHub Actions
- **Conflict Resolution**: Intelligent handling of merge conflicts during subtree operations
- **Branch Management**: Automatic creation of split branches for subtree operations

## Multi-Stage State Handling

The system handles all possible project states automatically:

| Local Files | Local Git | Remote Repo | Automation Action |
|-------------|-----------|-------------|-------------------|
| ❌ | ❌ | ❌ | Bootstrap from config |
| ❌ | ❌ | ✅ | Clone remote |
| ✅ | ❌ | ❌ | Create remote, init local, push |
| ✅ | ❌ | ✅ | Init local, pull remote |
| ✅ | ✅ | ❌ | Create remote, push |
| ✅ | ✅ | ✅ | Standard sync operations |

## Core Workflows

### Push Changes (`push-changes.yml`)
- Detects changed files and maps to subrepos using git subtree split
- Creates missing remotes automatically
- Initializes local git if needed
- Uses `git subtree push` for seamless history preservation
- Handles remote updates before pushing via subtree operations
- Creates conflict PRs for manual resolution during subtree merge conflicts

### Pull Changes (`pull-changes.yml`)
- Syncs updates from all subrepos using `git subtree pull`
- Handles missing local/remote scenarios with subtree add operations
- Merges changes into main repository preserving commit history
- Uses `--squash` option for clean merge history when appropriate
- Runs on schedule and manual trigger

### Bootstrap (`bootstrap.yml`)
- Complete setup from scratch using git subtree add operations
- Clones all configured repositories with full history preservation
- Creates missing remotes and initializes locals
- Uses subtree operations to establish initial mono-repo structure
- Verifies project integrity and subtree configuration

### Repository Deletion (`delete-repositories.yml`)
- Manual workflow requiring "DELETE" confirmation
- Creates backups before deletion
- Removes both local folders and remotes
- Updates configuration automatically

## Security & Performance

- **Authentication**: GitHub tokens with minimal permissions
- **Rate Limiting**: Intelligent backoff and batching
- **Parallel Processing**: Concurrent operations where safe
- **State Caching**: Optimized state detection
- **Audit Logging**: Complete operation trails

## Error Handling

- **Automatic Retry**: Transient failures with exponential backoff
- **Conflict Resolution**: Creates PRs for manual review
- **State Recovery**: Self-healing from inconsistent states
- **Emergency Procedures**: Manual shutdown and recovery