#/bin/bash

# This script checks if the current directory is part of a Git repository.
# If it is, and the repository is bare, it lists all the worktrees using `git worktree list`,
# shows them in a selecting list using fzf, and changes the current directory to the selected worktree.

isGitDir=$(git rev-parse --is-inside-git-dir)

if [ "$isGitDir" != "true" ]; then
    echo "Not a git repository."
    exit 1
fi

isBare=$(git rev-parse --is-bare-repository)

if [ "$isBare" != "true" ]; then
    echo "Not a bare git repository."
    exit 1
fi

wt_list=$(git worktree list --porcelain | grep worktree | awk '{print $2}')

if [ -z "$wt_list" ]; then
    echo "No worktrees found."
    exit 1
fi

selected_worktree=$(echo "$wt_list" | fzf --prompt="Select a worktree: ")
if [ -z "$selected_worktree" ]; then
    echo "No worktree selected."
    exit 1
fi

cd "$selected_worktree"
