#!/bin/bash
echo "time $(date)"
repo_locs=(/Users/ssurineni/ironman/my_notes
            # /Users/ssurineni/salesforce/my_notes
            /Users/ssurineni/ironman/atice
            /Users/ssurineni/ironman/problem-solving
          )

function commit_and_push {
    cd "${repo}" && echo `pwd` && git commit -am "$(date) $(whoami)"
    cd "${repo}" && git pull
    cd "${repo}" && git push
}
for repo in "${repo_locs[@]}"; do
    echo "******************************************************************"
    if [[ $repo == *"atice"* ]]; then
        cd "${repo}" && git add *.py && git add *.js
    fi
    # if [ "$repo" = "/Users/ssurineni/ironman/projects/atice" ]; then
    # cd "${repo}" && git add *.py
    # fi
    if [ "$repo" = "/Users/ssurineni/ironman/my_notes" ]; then
        cd "${repo}" && git add *.org
    fi
    if [ "$repo" = "/Users/ssurineni/ironman/problem-solving" ]; then
        cd "${repo}" && git add *.org
    fi
    # (cd "${repo}" && echo `pwd` && git commit -am "$(date) $(whoami)")
    # cd "${repo}" && git pull
    # cd "${repo}" && git push
    commit_and_push ${repo}
done
