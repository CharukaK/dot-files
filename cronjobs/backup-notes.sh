#/bin/bash

# This script wil backup the repository located in ~/local-repos/note-repo/ everyday through a cronjob using git

run_backup() {
    local DATE=$(date +%d-%m-%y)
    cd ~/local-repos/note-repo/
    git add -A
    git commit -m "Backup for day $DATE"
    git push origin main
}

run_backup

