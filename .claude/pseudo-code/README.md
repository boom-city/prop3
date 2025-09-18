# Boom Base Workflow Pseudo Code Documentation

## Overview

This directory contains pseudo code documentation for all GitHub Actions workflows in the Boom Base multi-repository management system. Each workflow has been analyzed and converted into clear, implementation-agnostic pseudo code that captures the essential logic patterns.

## Workflow Inventory

### Core Synchronization Workflows

1. **[PSEUDO-bootstrap.md](PSEUDO-bootstrap.md)** - Initial repository setup
   - **Purpose**: Clone and integrate all subrepos into monorepo structure
   - **Triggers**: Manual dispatch, repository creation, repository dispatch
   - **Key Features**: Parallel processing (10 concurrent), force re-clone option, error recovery

2. **[PSEUDO-auto-bootstrap.md](PSEUDO-auto-bootstrap.md)** - Automated new resource detection
   - **Purpose**: Automatically detect and bootstrap new repositories
   - **Triggers**: Push to config/resources, scheduled (6h), manual dispatch
   - **Key Features**: Smart detection, remote repo creation, integration with push workflow

3. **[PSEUDO-smart-sync.md](PSEUDO-smart-sync.md)** - Intelligent change detection and sync
   - **Purpose**: Advanced change analysis and automated repository management
   - **Triggers**: Push to main (excludes docs/workflows)
   - **Key Features**: Multi-state detection, auto-creation, force-with-lease push

### Bidirectional Synchronization

4. **[PSEUDO-push-subrepos.md](PSEUDO-push-subrepos.md)** - Monorepo to subrepos sync
   - **Purpose**: Push changes from monorepo to individual subrepos
   - **Triggers**: Push to main, manual dispatch
   - **Key Features**: Change detection, parallel sync (10 concurrent), auto repo creation

5. **[PSEUDO-pull-subrepos.md](PSEUDO-pull-subrepos.md)** - Subrepos to monorepo sync
   - **Purpose**: Pull changes from subrepos back to monorepo
   - **Triggers**: Manual dispatch, (scheduled - disabled)
   - **Key Features**: PR creation, conflict detection, filtering support

### Conflict Resolution and Upstream

6. **[PSEUDO-resolve-conflicts.md](PSEUDO-resolve-conflicts.md)** - Conflict resolution system
   - **Purpose**: Detect and resolve conflicts between monorepo and subrepos
   - **Triggers**: Manual dispatch, repository dispatch from other workflows
   - **Key Features**: Multiple strategies (ours/theirs/manual), conflict markers

7. **[PSEUDO-sync-upstream.md](PSEUDO-sync-upstream.md)** - Upstream repository sync
   - **Purpose**: Sync changes from upstream repositories
   - **Triggers**: Daily schedule (2 AM UTC), manual dispatch
   - **Key Features**: Upstream detection, merge conflict handling, subrepo distribution

## System Architecture Patterns

### State Management (6 Repository States)

The Boom Base system handles repositories in multiple states:

1. **Non-existent** - No local directory or remote repository
2. **Directory Only** - Local directory exists but no remote repository
3. **Remote Only** - Remote repository exists but no local directory
4. **Uninitialized** - Both exist but local lacks git initialization
5. **Out of Sync** - Both exist but content differs
6. **Synchronized** - Both exist and content matches

### Workflow Orchestration Patterns

```
TRIGGER EVENT
    ↓
CHANGE DETECTION
    ↓
STATE ANALYSIS
    ↓
┌─────────────────┬─────────────────┬─────────────────┐
│   BOOTSTRAP     │    SYNC        │   CONFLICT      │
│   (if needed)   │   (if changes) │   (if detected) │
└─────────────────┴─────────────────┴─────────────────┘
    ↓
VERIFICATION & SUMMARY
```

### Critical Implementation Patterns

#### Parallel Processing
- **Batch Size**: Maximum 10 concurrent operations
- **Rate Limiting**: Built-in delays to prevent GitHub API exhaustion
- **Error Isolation**: Individual failures don't stop batch processing

#### Git Integration Strategies
- **Bootstrap**: Direct clone + .git removal (monorepo integration)
- **Push**: Complete file sync with force push
- **Pull**: rsync-based difference detection + PR creation
- **Conflict Resolution**: Multiple strategies with manual fallback

#### State Validation
```
FOR EACH repository:
    IF NOT directory_exists(local_path):
        state = "missing_local"
    ELIF NOT remote_repository_exists(remote_url):
        state = "missing_remote"
    ELIF NOT directory_has_git_init(local_path):
        state = "uninitialized"
    ELIF files_differ(local_path, remote_content):
        state = "out_of_sync"
    ELSE:
        state = "synchronized"
```

## Key Architectural Principles

### 1. **Non-Destructive Operations**
- Pull operations create PRs instead of direct commits
- Conflict resolution provides multiple strategies
- Force options require explicit user confirmation

### 2. **Comprehensive Error Handling**
- Graceful degradation when repositories are inaccessible
- Detailed error logging and artifact creation
- Automatic issue creation for manual intervention

### 3. **CI/CD Integration**
- Uses `[skip ci]` to prevent infinite workflow loops
- Conditional execution based on actual changes
- Integration points between workflows

### 4. **Security and Rate Limiting**
- Enhanced token usage (GH_PAT) for repository operations
- Batch processing limits to respect GitHub API limits
- Private repository creation by default

## Workflow Dependencies and Integration

### Trigger Chains
```
Config Change → Auto-Bootstrap → Smart-Sync → Push-Subrepos
      ↓              ↓              ↓            ↓
Repository     Local Setup    Change        Subrepo
Creation       + README       Detection     Updates
```

### Error Escalation
```
Automated Process → Conflict Detection → Issue Creation → Manual Resolution
```

### State Synchronization
```
Local Changes → Push-Subrepos → Remote Updates
Remote Changes → Pull-Subrepos → PR Creation → Review → Merge
```

## Common Implementation Patterns

### Branch Management
```
FUNCTION create_unique_branch(operation_type):
    timestamp = format_datetime("YYYYMMDD-HHMMSS")
    branch_name = operation_type + "-" + timestamp
    RETURN sanitize_branch_name(branch_name)
```

### Temporary Directory Handling
```
FUNCTION with_temp_directory(operation):
    temp_dir = create_temp_directory()
    TRY:
        operation(temp_dir)
    FINALLY:
        cleanup_temp_directory(temp_dir)
```

### Git Operations Safety
```
FUNCTION safe_git_operation(operation):
    TRY:
        result = operation()
        RETURN {success: true, result: result}
    CATCH git_error:
        log_error(git_error)
        RETURN {success: false, error: git_error}
```

## Configuration Dependencies

All workflows depend on `.github/subrepo-config.json` structure:
```json
{
  "subrepos": [
    {
      "prefix": "resources/[category]/resource-name",
      "remote": "https://github.com/owner/repo-name.git",
      "branch": "main"
    }
  ]
}
```

## Monitoring and Observability

### GitHub Actions Integration
- **Step Summaries**: Detailed results in GitHub Actions UI
- **Artifact Uploads**: Error logs and processing summaries
- **Issue Creation**: Automatic issue creation for manual intervention
- **PR Creation**: Pull requests for review workflows

### Logging Patterns
- **Success Markers**: ✓ for successful operations
- **Warning Markers**: ⚠ for recoverable issues
- **Error Markers**: ✗ for failed operations
- **Info Markers**: ℹ️ for informational messages

This pseudo code documentation provides a complete overview of the Boom Base workflow system, enabling developers to understand the logic flow without needing to parse the actual YAML implementations.