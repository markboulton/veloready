#!/bin/bash

# VeloReady Development Workflow - Single Developer
# Streamlined workflow for fast development

set -e

echo "🚀 VeloReady Development Workflow"
echo "================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -d "VeloReady.xcworkspace" ] && [ ! -d "VeloReady.xcodeproj" ]; then
    print_error "Please run this script from the VeloReady project root"
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start new feature branch"
    echo "  test      - Run quick test (90s)"
    echo "  push      - Push changes (with quick test)"
    echo "  ship      - Ship to main (with full validation)"
    echo "  status    - Show current status"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 start feature/strava-cache-fix"
    echo "  $0 test"
    echo "  $0 push"
    echo "  $0 ship"
}

# Function to start new feature
start_feature() {
    local branch_name=$1
    
    if [ -z "$branch_name" ]; then
        print_error "Please provide a branch name"
        echo "Usage: $0 start feature/your-feature-name"
        exit 1
    fi
    
    print_info "Starting new feature: $branch_name"
    
    # Check if we're on main
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_warning "Not on main branch (currently on $current_branch)"
        read -p "Switch to main first? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git checkout main
            git pull origin main
        fi
    fi
    
    # Create and checkout new branch
    git checkout -b "$branch_name"
    print_status "Created and switched to branch: $branch_name"
    
    print_info "Ready to code! Next steps:"
    echo "  1. Code your feature"
    echo "  2. Run: $0 test"
    echo "  3. Run: $0 push"
}

# Function to run quick test
run_test() {
    print_info "Running quick test (90 seconds max)..."
    ./Scripts/quick-test.sh
}

# Function to push changes
push_changes() {
    print_info "Pushing changes with quick test..."
    
    # Run quick test first
    if ! ./Scripts/quick-test.sh; then
        print_error "Quick test failed - fix issues before pushing"
        exit 1
    fi
    
    # Get current branch
    current_branch=$(git branch --show-current)
    
    # Add all changes
    git add .
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        print_warning "No changes to commit"
        return 0
    fi
    
    # Commit with a simple message
    echo "Enter commit message (or press Enter for auto-generated):"
    read -r commit_message
    
    if [ -z "$commit_message" ]; then
        # Auto-generate commit message
        commit_message="feat: $(git diff --cached --name-only | head -1 | sed 's/.*\///' | sed 's/\..*//' | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')"
    fi
    
    git commit -m "$commit_message"
    
    # Push to origin
    git push origin "$current_branch"
    
    print_status "Pushed to origin/$current_branch"
    print_info "CI will run additional tests (5-10 minutes)"
}

# Function to ship to main
ship_to_main() {
    current_branch=$(git branch --show-current)
    
    if [ "$current_branch" = "main" ]; then
        print_error "Already on main branch"
        exit 1
    fi
    
    print_info "Shipping $current_branch to main..."
    
    # Run quick test first
    if ! ./Scripts/quick-test.sh; then
        print_error "Quick test failed - fix issues before shipping"
        exit 1
    fi
    
    # Switch to main and merge
    git checkout main
    git pull origin main
    git merge "$current_branch"
    
    # Push to main
    git push origin main
    
    print_status "Shipped to main!"
    print_info "CI will run full validation (10-15 minutes)"
    
    # Ask if user wants to delete the feature branch
    read -p "Delete feature branch $current_branch? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -d "$current_branch"
        git push origin --delete "$current_branch"
        print_status "Deleted feature branch"
    fi
}

# Function to show status
show_status() {
    print_info "Current Status:"
    echo ""
    
    # Git status
    echo "📊 Git Status:"
    git status --short
    echo ""
    
    # Current branch
    current_branch=$(git branch --show-current)
    echo "🌿 Current Branch: $current_branch"
    
    # Last commit
    echo "📝 Last Commit:"
    git log -1 --oneline
    echo ""
    
    # CI status (if available)
    if command -v gh &> /dev/null; then
        echo "🔄 CI Status:"
        gh run list --limit 1 --json status,conclusion,headBranch
    else
        echo "🔄 CI Status: Check GitHub Actions manually"
    fi
}

# Main script logic
case "${1:-help}" in
    "start")
        start_feature "$2"
        ;;
    "test")
        run_test
        ;;
    "push")
        push_changes
        ;;
    "ship")
        ship_to_main
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_usage
        ;;
esac
