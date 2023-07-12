#!/bin/bash
repo_locs=(/Users/ssurineni/ironman/my_notes
            /Users/ssurineni/salesforce/my_notes)
for repo in "${repo_locs[@]}"; do
    (cd "${repo}" && echo `pwd` && git commit -am "update" && git pull )
    cd "${repo}" && git push
done
