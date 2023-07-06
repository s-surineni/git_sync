#!/bin/bash
repo_locs=(/home/sampath/projects/my_notes)
for repo in "${repo_locs[@]}"; do
    echo `pwd`
    (cd "${repo}" && git pull && git commit -m "update" && git push)
done
