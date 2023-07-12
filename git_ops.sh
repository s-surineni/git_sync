#!/bin/bash
date
repo_locs=(/home/sampath/projects/my_notes
           /home/sampath/projects/git_sync
           /home/sampath/projects/settings)
for repo in "${repo_locs[@]}"; do
    (cd "${repo}" && echo `pwd` && git commit -am "update" && git pull )
    cd "${repo}" && git push
done
