#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# runs on every commit pushed to github.
# => just need to check one commit at a time.

# --------------------------------[ Functions ]----------------------------------
function fail(){
    local color_end=$'\033[0m'
    local red='\033[0;31m'

    echo -e "${red}Error: $1"
    echo -e "$color_end"

    exit 1
}

function success(){
    local color_end=$'\033[0m'
    local green='\033[0;32m'

    echo -e "${green}Notice: $1"
    echo -e "$color_end"
    echo "$1"

    exit 0
}

# ---------------------------------[ Checks ]------------------------------------

# fail the build if file in the guide/ folder has changed,
# => is generated, needs to be changed in neomutt repository.
if [[ $(git diff-tree --no-commit-id --name-only -r HEAD |
               grep --color=never -E '.*guide.*' ) > "" ]]
then
    variable=$(cat <<EOF
Every file in the guide/ directory is automatically generated from the manual
https://github.com/neomutt/neomutt/tree/neomutt/doc/manual.xml.head - So please,
do your changes there.
EOF
)
    fail "$variable"

fi

# -------------------------------------------------------------------------------

# fail if manpages were edited.
# => is generated, needs to be changed in neomutt repository.
if [[ $(git diff-tree --no-commit-id --name-only -r HEAD |
               grep --color=never -E '.*_man.*' ) > "" ]]
then
    variable=$(cat <<EOF
Every file in the _man/ directory is automatically generated from the manpages
in https://github.com/neomutt/neomutt/tree/neomutt/doc/ - So please,
do your changes there.
EOF
)
    fail "$variable"
fi

# -------------------------------------------------------------------------------

# exit successfully if any file was edited, which html-proofer can't check
if [[ $(git diff-tree --no-commit-id --name-only -r HEAD |
               grep --color=never -E \
                    -e '.*\.md' \
                    -e '.*\.markdown' \
                    -e '*\.yml'
        ) > "" ]]
then

    variable=$(cat <<EOF
Some files which html-proofer can't check were edited, exit successfully.
EOF
)
    success "$variable"
fi
