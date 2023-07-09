#!/bin/bash
repo_locs=(/home/sampath/projects/my_notes
           /home/sampath/projects/git_sync)
for repo in "${repo_locs[@]}"; do
    echo `pwd`
    (cd "${repo}" && git pull &&  git commit -am "update" && git push)
done
