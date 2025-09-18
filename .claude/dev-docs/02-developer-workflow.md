# Developer Workflow

## Getting Started

### New Developer Setup
```bash
# Clone main repository (bootstraps automatically)
git clone https://github.com/boom-city/boom-base.git
cd boom-base

# Verify all subtrees are set up
find resources -name ".git" -type d | wc -l  # Should match config count

# Check subtree configuration
git log --oneline --grep="git-subtree" | head -10
```

The system automatically detects when starting from scratch and bootstraps all subrepos using git subtree operations during the first push or pull operation. This preserves complete commit history for each resource while maintaining a unified mono-repo structure.

## Daily Development

### Standard Git Workflow (Enhanced with Subtree)
```bash
# Make changes to any resources
vim resources/[qbx]/qbx_core/client.lua

# Normal git operations (unchanged for developers)
git add .
git commit -m "Fix vehicle spawn issue"
git push origin main

# Automation handles (using git subtree):
# - Detecting affected subrepos via subtree split
# - Creating missing remotes if needed
# - Using git subtree push to preserve commit history
# - Maintaining parent-child relationship between mono-repo and subrepos
# - Automatic conflict resolution during subtree operations
```

### Understanding Git Subtree vs Traditional Subrepos
- **History Preservation**: Unlike traditional subrepo patterns, git subtree maintains complete commit history
- **Seamless Integration**: Changes appear in both mono-repo and individual subrepo histories
- **No Special Commands**: Developers use standard git commands; subtree operations are automated
- **Conflict Resolution**: Subtree merge conflicts are handled automatically by the workflow system

### Adding New Resources
```bash
# 1. Create resource folder
mkdir -p resources/[boom-scripts]/my-new-script
echo "print('Hello')" > resources/[boom-scripts]/my-new-script/client.lua

# 2. Add to configuration
vim .github/subrepo-config.json
# Add: {
#   "prefix": "resources/[boom-scripts]/my-new-script",
#   "remote": "https://github.com/boom-city/my-new-script.git",
#   "branch": "main"
# }

# 3. Commit and push
git add .
git commit -m "Add new script: my-new-script"
git push  # Automation creates remote and uses git subtree push with full history
```

### Removing Resources
```bash
# 1. Remove local folder and config entry
rm -rf resources/[boom-scripts]/old-script
vim .github/subrepo-config.json  # Remove entry
git add .
git commit -m "Remove deprecated old-script"
git push

# 2. Delete remote repository (manual workflow)
gh workflow run delete-repositories.yml \
  --field repositories="old-script" \
  --field confirm_deletion="DELETE" \
  --field backup_before_delete=true
```

## Handling Different Scenarios

### Starting from Scratch
The system detects empty state and automatically:
- Creates directory structure from config
- Uses `git subtree add` to integrate all existing remotes with full history
- Sets up local git configuration
- Preserves complete commit history from individual repositories

### Partial Setup
When some repos are missing:
- Automation detects gaps during operations
- Creates missing remotes automatically
- Uses `git subtree add` for missing subtrees with history preservation
- Initializes uninitialized locals
- No developer intervention needed

### Merge Conflicts
When subtree merge conflicts occur:
1. Automation creates conflict resolution PR
2. Review and check out the branch:
```bash
git fetch origin
git checkout automated-conflict-resolution-branch
# Resolve subtree merge conflicts manually
git add resolved-files
git commit -m "Resolve subtree merge conflicts"
git push origin automated-conflict-resolution-branch
```
3. Merge PR when ready

**Note**: Subtree conflicts are typically caused by:
- Concurrent changes in mono-repo and individual subrepo
- Manual subtree operations outside the automation system
- History divergence between mono-repo and subrepo branches

## Best Practices

### Commits
- Use descriptive messages
- Keep commits focused
- Reference issues when applicable

### File Organization
- Follow established folder structure
- Use consistent naming conventions
- Place resources in appropriate categories

### Configuration
- Always update `subrepo-config.json` for new resources
- Validate configuration before committing
- Use helper scripts for bulk updates

### Subtree-Specific Best Practices
- **Avoid manual subtree operations**: Let automation handle subtree push/pull/add
- **Commit atomically**: Make focused commits that affect single resources when possible
- **Monitor subtree history**: Use `git log --grep="git-subtree"` to track subtree operations
- **Understand merge commits**: Subtree operations create merge commits that preserve history
- **Branch carefully**: Avoid creating branches that span multiple subtrees

## Troubleshooting

### Common Issues

**Push rejected:**
```bash
git pull origin main  # Pull latest changes
git push origin main  # Try again
```

**Missing repository:**
- Automation creates it automatically
- Check workflow logs for status
- Verify GitHub permissions

**Sync issues:**
```bash
gh workflow run pull-changes.yml  # Manual sync using subtree pull
gh issue list --label="sync-conflict"  # Check conflicts

# Subtree-specific sync diagnostics
git log --oneline --grep="git-subtree" | head -10  # Recent subtree operations
git subtree --help  # Verify subtree availability
```

### Getting Help
- Check workflow logs in GitHub Actions
- Review automation-created issues
- Contact development team for complex issues

### Emergency Procedures
```bash
# Emergency stop (if needed)
gh workflow disable push-changes.yml
gh workflow disable pull-changes.yml

# Make manual fixes
# Re-enable when ready
gh workflow enable push-changes.yml
gh workflow enable pull-changes.yml
```