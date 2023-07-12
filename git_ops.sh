#!/bin/bash
date
repo_locs=(/Users/ssurineni/ironman/my_notes
            /Users/ssurineni/salesforce/my_notes
            /Users/ssurineni/ironman/projects/atice)
for repo in "${repo_locs[@]}"; do
    (cd "${repo}" && echo `pwd` && git commit -am "$(date) $(hostname)" && git pull )
    cd "${repo}" && git push
done
