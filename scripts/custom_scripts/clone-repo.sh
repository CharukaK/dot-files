#!/usr/bin/env bash

if [ $# -lt 1 ]; then
    echo "Usage: crepo <git-url>"
    exit 1
fi

selected=$(echo -e "/home/charuka/repos\n/home/charuka/test-projects" | fzf --header "select root dir:" --reverse)

if [[ -z $selected ]]; then 
    exit 0
fi

# Extract repo name from git URL
repo_name=$(basename "$1" .git)

# Clone to a subdirectory within the selected root
git clone "$1" "$selected/$repo_name" --bare

