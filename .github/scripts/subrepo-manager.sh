#!/bin/bash

# Subrepo Manager - Core operations script for managing subrepos
# This script provides utility functions for subrepo operations

set -e

# Configuration
CONFIG_FILE="${CONFIG_FILE:-.github/subrepo-config.json}"
GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN}}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

debug() {
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure required tools are installed
check_requirements() {
    local missing_tools=()

    if ! command_exists git; then
        missing_tools+=("git")
    fi

    if ! command_exists jq; then
        missing_tools+=("jq")
    fi

    if ! command_exists gh; then
        missing_tools+=("gh (GitHub CLI)")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        error "Please install the missing tools and try again."
        exit 1
    fi
}

# Function to validate configuration file
validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        error "Invalid JSON in configuration file: $CONFIG_FILE"
        exit 1
    fi

    local subrepo_count
    subrepo_count=$(jq '.subrepos | length' "$CONFIG_FILE")

    if [ "$subrepo_count" -eq 0 ]; then
        warning "No subrepos defined in configuration"
        return 1
    fi

    log "Found $subrepo_count subrepos in configuration"
    return 0
}

# Function to get all subrepo configurations
get_all_subrepos() {
    jq -c '.subrepos[]' "$CONFIG_FILE"
}

# Function to get a specific subrepo by prefix
get_subrepo_by_prefix() {
    local prefix="$1"
    jq -c ".subrepos[] | select(.prefix == \"$prefix\")" "$CONFIG_FILE"
}

# Function to check if a GitHub repository exists
repo_exists() {
    local repo="$1"

    if gh repo view "$repo" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to create a GitHub repository
create_github_repo() {
    local repo_owner="$1"
    local repo_name="$2"
    local description="$3"
    local visibility="${4:-private}"

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would create repository: $repo_owner/$repo_name"
        return 0
    fi

    log "Creating repository: $repo_owner/$repo_name"

    if gh repo create "$repo_owner/$repo_name" \
        --"$visibility" \
        --description "$description" 2>/dev/null; then
        success "Repository created: $repo_owner/$repo_name"
        return 0
    else
        error "Failed to create repository: $repo_owner/$repo_name"
        return 1
    fi
}

# Function to clone a subrepo
clone_subrepo() {
    local prefix="$1"
    local remote="$2"
    local branch="$3"
    local target_dir="${4:-$prefix}"

    debug "Cloning $remote to $target_dir"

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would clone $remote to $target_dir"
        return 0
    fi

    if [ -d "$target_dir/.git" ]; then
        warning "Directory already contains a git repository: $target_dir"
        return 1
    fi

    if git clone --branch "$branch" --single-branch "$remote" "$target_dir" 2>/dev/null; then
        success "Cloned $remote to $target_dir"
        return 0
    else
        error "Failed to clone $remote"
        return 1
    fi
}

# Function to sync changes to a subrepo
sync_to_subrepo() {
    local prefix="$1"
    local remote="$2"
    local branch="$3"
    local commit_message="${4:-Sync from monorepo}"

    debug "Syncing $prefix to $remote"

    if [ ! -d "$prefix" ]; then
        error "Source directory not found: $prefix"
        return 1
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would sync $prefix to $remote"
        return 0
    fi

    # Create temporary directory for subrepo
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Clone or initialize subrepo
    if ! git clone "$remote" "$temp_dir" 2>/dev/null; then
        debug "Repository doesn't exist or is empty, initializing new repo"
        git init "$temp_dir"
        cd "$temp_dir"
        git checkout -b "$branch"
        git remote add origin "$remote"
    else
        cd "$temp_dir"
        git checkout "$branch" || git checkout -b "$branch"
    fi

    # Copy files from monorepo to subrepo
    rsync -a --delete \
          --exclude='.git' \
          "$GITHUB_WORKSPACE/$prefix/" "$temp_dir/"

    # Check for changes
    if [ -z "$(git status --porcelain)" ]; then
        log "No changes to sync for $prefix"
        return 0
    fi

    # Commit and push changes
    git add -A
    git commit -m "$commit_message"

    if git push origin "$branch"; then
        success "Synced changes to $remote"
        return 0
    else
        error "Failed to push changes to $remote"
        return 1
    fi
}

# Function to sync changes from a subrepo
sync_from_subrepo() {
    local prefix="$1"
    local remote="$2"
    local branch="$3"

    debug "Syncing from $remote to $prefix"

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would sync from $remote to $prefix"
        return 0
    fi

    # Create temporary directory for subrepo
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Clone the subrepo
    if ! git clone --branch "$branch" "$remote" "$temp_dir" 2>/dev/null; then
        warning "Failed to clone $remote"
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "$prefix"

    # Sync files from subrepo to monorepo
    rsync -a --delete \
          --exclude='.git' \
          "$temp_dir/" "$prefix/"

    success "Synced changes from $remote to $prefix"
    return 0
}

# Function to detect changed subrepos
detect_changed_subrepos() {
    local commit_range="${1:-HEAD~1..HEAD}"
    local changed_files

    debug "Detecting changes in range: $commit_range"

    # Get list of changed files
    if [[ "$commit_range" == *".."* ]]; then
        changed_files=$(git diff --name-only "$commit_range")
    else
        changed_files=$(git diff-tree --no-commit-id --name-only -r "$commit_range")
    fi

    # Map files to subrepos
    local changed_subrepos=()
    while IFS= read -r file; do
        [ -z "$file" ] && continue

        while IFS= read -r subrepo_json; do
            local prefix
            prefix=$(echo "$subrepo_json" | jq -r '.prefix')

            if [[ "$file" == "$prefix/"* ]] || [[ "$file" == "$prefix" ]]; then
                # Add to array if not already present
                if [[ ! " ${changed_subrepos[@]} " =~ " ${subrepo_json} " ]]; then
                    changed_subrepos+=("$subrepo_json")
                fi
                break
            fi
        done < <(get_all_subrepos)
    done <<< "$changed_files"

    # Output changed subrepos as JSON array
    printf '%s\n' "${changed_subrepos[@]}" | jq -s .
}

# Function to process a single subrepo
process_subrepo() {
    local action="$1"
    local subrepo_json="$2"

    local prefix remote branch
    prefix=$(echo "$subrepo_json" | jq -r '.prefix')
    remote=$(echo "$subrepo_json" | jq -r '.remote')
    branch=$(echo "$subrepo_json" | jq -r '.branch')

    log "Processing $prefix (action: $action)"

    case "$action" in
        clone)
            clone_subrepo "$prefix" "$remote" "$branch"
            ;;
        push|sync-to)
            sync_to_subrepo "$prefix" "$remote" "$branch"
            ;;
        pull|sync-from)
            sync_from_subrepo "$prefix" "$remote" "$branch"
            ;;
        create-repo)
            local repo_owner repo_name
            repo_owner=$(echo "$remote" | sed -E 's|.*github\.com[:/]([^/]+)/.*|\1|')
            repo_name=$(echo "$remote" | sed -E 's|.*/([^/]+)\.git$|\1|')

            if ! repo_exists "$repo_owner/$repo_name"; then
                create_github_repo "$repo_owner" "$repo_name" \
                    "Subrepo for $prefix" "private"
            else
                log "Repository already exists: $repo_owner/$repo_name"
            fi
            ;;
        *)
            error "Unknown action: $action"
            return 1
            ;;
    esac
}

# Main function
main() {
    local action="${1:-help}"
    shift || true

    check_requirements
    validate_config || true

    case "$action" in
        clone-all)
            log "Cloning all subrepos..."
            get_all_subrepos | while IFS= read -r subrepo; do
                process_subrepo "clone" "$subrepo"
            done
            ;;

        push-all)
            log "Pushing to all subrepos..."
            get_all_subrepos | while IFS= read -r subrepo; do
                process_subrepo "push" "$subrepo"
            done
            ;;

        pull-all)
            log "Pulling from all subrepos..."
            get_all_subrepos | while IFS= read -r subrepo; do
                process_subrepo "pull" "$subrepo"
            done
            ;;

        detect-changes)
            local commit_range="${1:-HEAD~1..HEAD}"
            detect_changed_subrepos "$commit_range"
            ;;

        create-repos)
            log "Creating missing GitHub repositories..."
            get_all_subrepos | while IFS= read -r subrepo; do
                process_subrepo "create-repo" "$subrepo"
            done
            ;;

        help|--help|-h)
            cat << EOF
Subrepo Manager - Manage multiple subrepos from a monorepo

Usage: $0 [action] [options]

Actions:
  clone-all       Clone all configured subrepos
  push-all        Push changes to all subrepos
  pull-all        Pull changes from all subrepos
  detect-changes  Detect which subrepos have changes
  create-repos    Create missing GitHub repositories
  help            Show this help message

Environment Variables:
  CONFIG_FILE     Path to subrepo configuration (default: .github/subrepo-config.json)
  GH_TOKEN        GitHub token for API operations
  DRY_RUN         Run in dry-run mode (true/false, default: false)
  VERBOSE         Enable verbose output (true/false, default: false)

Examples:
  $0 clone-all
  $0 detect-changes HEAD~5..HEAD
  DRY_RUN=true $0 push-all
EOF
            ;;

        *)
            error "Unknown action: $action"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi