#!/bin/bash
echo "time $(date)"
repo_locs=(/home/sampath/projects/my_notes
           /home/sampath/projects/git_sync
           /home/sampath/projects/settings)
for repo in "${repo_locs[@]}"; do
    echo "******************************************************************"
    if [ "$repo" = "/Users/ssurineni/ironman/projects/atice" ]; then
    cd "${repo}" && git add *.py
    fi
    (cd "${repo}" && echo `pwd` && git commit -am "$(date) $(whoami)" && git pull )
    cd "${repo}" && git push
done
