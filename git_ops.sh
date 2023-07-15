#!/bin/bash
echo "time $(date)"
repo_locs=(/Users/ssurineni/ironman/my_notes
            /Users/ssurineni/salesforce/my_notes
            /Users/ssurineni/ironman/projects/atice)
for repo in "${repo_locs[@]}"; do
    echo "******************************************************************"
    if [ "$repo" = "/Users/ssurineni/ironman/projects/atice" ]; then
    cd "${repo}" && git add *.py
    fi
    (cd "${repo}" && echo `pwd` && git commit -am "$(date) $(whoami)")
    cd "${repo}" && git pull
    cd "${repo}" && git push
done
