# Operations Guide

## Monitoring

### Health Checks
```bash
# Daily automated health check
gh workflow run health-check.yml

# Manual state inspection with subtree validation
for prefix in $(jq -r '.subrepos[].prefix' .github/subrepo-config.json); do
  echo "Checking: $prefix"
  [ -d "$prefix" ] && echo "  ✅ Local files" || echo "  ❌ Missing local"
  [ -d "$prefix/.git" ] && echo "  ✅ Git init" || echo "  ❌ No git"
  
  # Check if prefix is a valid subtree
  if git log --oneline --grep="git-subtree-dir: $prefix" >/dev/null 2>&1; then
    echo "  ✅ Subtree configured"
  else
    echo "  ⚠️  Not a subtree or missing subtree commits"
  fi
done

# Validate subtree integrity
git log --oneline --grep="git-subtree" | head -10
```

### Performance Metrics
- Workflow execution times (subtree operations can be slower than standard git)
- API rate limit usage
- Success/failure rates
- Sync lag monitoring
- Subtree operation performance (split/push/pull times)
- History preservation verification

### Alerting Thresholds
- **Critical**: Workflow failure rate > 10%
- **Warning**: API usage > 80%
- **Info**: Sync lag > 4 hours
- **Subtree-specific**: Failed subtree operations or history corruption

## Maintenance

### Daily Tasks
```bash
# Automated daily maintenance
gh workflow run health-check.yml
gh run list --status=failure  # Check for failures

# Subtree-specific maintenance
git log --oneline --grep="git-subtree" --since="24 hours ago"  # Recent subtree operations
git fsck --full  # Verify repository integrity after subtree operations
```

### Weekly Tasks
- Configuration audit
- Performance review
- Security audit
- Dependency updates

### Monthly Tasks
- Full system sync
- Backup verification
- Documentation updates
- Capacity planning

## Configuration Management

### Validation
```bash
# Validate configuration
jq empty .github/subrepo-config.json  # JSON syntax
# Check for duplicates, test remote access
```

### Backup Strategy
- **Configuration**: On every change, 1 year retention
- **Repository state**: Daily, 90 days retention
- **Audit logs**: Real-time, 1 year retention

### Safe Updates
```bash
# Configuration update procedure
cp .github/subrepo-config.json .github/subrepo-config.json.backup
# Edit configuration
./scripts/validate-config.sh
gh workflow run sync-state.yml --field dry_run=true
git add .github/subrepo-config.json
git commit -m "Update configuration"
git push
```

## Git Subtree Operations

### Manual Subtree Commands
```bash
# Add a new subtree
git subtree add --prefix=resources/[category]/repo-name \
  https://github.com/org/repo-name.git main --squash

# Pull updates from subtree remote
git subtree pull --prefix=resources/[category]/repo-name \
  https://github.com/org/repo-name.git main --squash

# Push changes to subtree remote
git subtree push --prefix=resources/[category]/repo-name \
  https://github.com/org/repo-name.git main

# Split subtree into separate branch (for history extraction)
git subtree split --prefix=resources/[category]/repo-name -b temp-split-branch

# Create new remote repository from subtree
git push https://github.com/org/new-repo.git temp-split-branch:main
```

### Subtree History Management
```bash
# View subtree commits
git log --oneline --grep="git-subtree-dir: resources/[category]/repo-name"

# Check subtree merge commits
git log --merges --oneline --grep="git-subtree"

# Verify subtree integrity
git log --oneline resources/[category]/repo-name | head -10

# Find all subtrees in repository
git log --grep="git-subtree-dir:" --pretty=format:"%s" | \
  sed -n 's/.*git-subtree-dir: \(.*\)$/\1/p' | sort -u
```

## Troubleshooting

### Common Issues

#### Authentication Failures
```bash
# Check token validity
gh auth status
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Solutions:
# - Regenerate expired tokens
# - Verify token permissions
# - Check rate limits
```

#### State Mismatches
```bash
# Diagnose state issues
gh workflow run sync-state.yml
gh run view --log  # Check execution details

# Subtree-specific diagnostics
git log --oneline --grep="git-subtree" | head -20
git subtree --help  # Verify git subtree is available

# Solutions:
# - Force full sync: gh workflow run pull-changes.yml --field force_full_sync=true
# - Manual resolution for conflicts
# - State reset if needed
# - Subtree re-add if history is corrupted
```

#### Subtree Operation Failures
```bash
# Common subtree issues and solutions

# Issue: "Working tree has modifications"
git status  # Check for uncommitted changes
git stash   # Temporarily stash changes
git subtree pull --prefix=path/to/subtree remote main --squash
git stash pop  # Restore stashed changes

# Issue: "fatal: ambiguous argument 'HEAD^{tree}'"
git log --oneline -10  # Verify commit history exists
git subtree add --prefix=path/to/subtree remote main --squash  # Re-add if needed

# Issue: Merge conflicts during subtree pull
git status  # Identify conflicted files
# Resolve conflicts manually
git add .
git commit -m "Resolve subtree merge conflicts"

# Issue: Subtree push rejected
git subtree pull --prefix=path/to/subtree remote main --squash  # Pull first
git subtree push --prefix=path/to/subtree remote main  # Then push
```

#### Repository Lifecycle Issues
```bash
# Handle orphaned repositories
gh workflow run sync-state.yml  # Identifies orphans

# Clean up unwanted repos
gh workflow run delete-repositories.yml \
  --field repositories="repo1,repo2" \
  --field confirm_deletion="DELETE"
```

### Diagnostic Tools

#### State Analysis
```bash
#!/bin/bash
# State inspection script
CONFIG_FILE=".github/subrepo-config.json"
for prefix in $(jq -r '.subrepos[].prefix' "$CONFIG_FILE"); do
    echo "=== $prefix ==="
    [ -d "$prefix" ] && echo "Local: ✅" || echo "Local: ❌"
    [ -d "$prefix/.git" ] && echo "Git: ✅" || echo "Git: ❌"
    
    remote=$(jq -r ".subrepos[] | select(.prefix==\"$prefix\") | .remote" "$CONFIG_FILE")
    repo_name=$(basename "$remote" .git)
    org_name=$(basename "$(dirname "$remote")")
    gh repo view "$org_name/$repo_name" >/dev/null 2>&1 && echo "Remote: ✅" || echo "Remote: ❌"
done
```

#### Performance Analysis
```bash
# Workflow execution times
gh run list --limit=10 --json name,createdAt,updatedAt | \
jq '.[] | {name: .name, duration: (.updatedAt | fromdateiso8601) - (.createdAt | fromdateiso8601)}'

# API usage
curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/rate_limit | jq '.rate'
```

## Emergency Procedures

### Emergency Shutdown
```bash
#!/bin/bash
echo "🚨 EMERGENCY SHUTDOWN"

# Disable all workflows
WORKFLOWS=("push-changes.yml" "pull-changes.yml" "sync-state.yml" "bootstrap.yml")
for workflow in "${WORKFLOWS[@]}"; do
    gh workflow disable "$workflow"
done

# Create emergency issue
gh issue create \
  --title "🚨 EMERGENCY: Automation Shutdown" \
  --label "emergency" \
  --body "System shutdown. Manual intervention required."

echo "✅ Shutdown complete"
```

### Recovery Procedure
```bash
#!/bin/bash
echo "🔧 Starting recovery..."

# Validate system state
./scripts/state-inspection.sh || exit 1

# Test configuration
./scripts/validate-config.sh || exit 1

# Test workflows
gh workflow run sync-state.yml --field dry_run=true
sleep 60

# Check test results
LATEST_RUN=$(gh run list --workflow=sync-state.yml --limit=1 --json id --jq '.[0].id')
STATUS=$(gh run view "$LATEST_RUN" --json status --jq '.status')
[ "$STATUS" = "completed" ] || exit 1

# Re-enable workflows
for workflow in "${WORKFLOWS[@]}"; do
    gh workflow enable "$workflow"
done

echo "✅ Recovery complete"
```

## Security

### Token Management
- Use minimal required permissions
- Regular token rotation
- Store in GitHub Secrets
- Monitor for unauthorized usage

### Access Control
- Repository-level permissions
- Branch protection rules
- Team access management
- Webhook security

### Audit Logging
```bash
# Comprehensive audit entry
LOG_ENTRY=$(cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "operation": "$OPERATION",
  "user": "$GITHUB_ACTOR",
  "repository": "$REPOSITORY",
  "status": "$STATUS"
}
EOF
)
echo "$LOG_ENTRY" >> audit.log
```

## Support

### Escalation Levels
1. **Documentation** - Check guides and common solutions
2. **GitHub Issues** - Create issue with diagnostic information
3. **Team Contact** - Reach out to development team
4. **Emergency** - Use emergency procedures for critical failures

### Creating Support Tickets
Include:
- System state analysis output
- Recent workflow logs
- Error messages and context
- Steps attempted for resolution