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
}

function success(){
    local color_end=$'\033[0m'
    local green='\033[0;32m'

    echo -e "${green}Notice: $1"
    echo -e "$color_end"
}

function notice(){
    local color_end=$'\033[0m'
    local purple='\033[0;35m'

    echo -e "${purple}Notice: $1"
    echo -e "$color_end"
}

function install_apt(){
    apt-get update -y
    apt-get install -y "$@"
}

function install_gem(){
    gem install "$@"
}


# ---------------------------------[ Checks ]------------------------------------

notice "Checking for changes in guide/ folder.."

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
    exit 1

else
    notice "no changes in guide/ folder detected."
fi

# -------------------------------------------------------------------------------


notice "checking for changes in _man/ folder."

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
    exit 1
else
    notice "no changes in _man/ folder detected."
fi

# -------------------------------------------------------------------------------

notice "Checking if only files have been edited, which weren't web or markdown
files"

# exit successfully if only files were edited, which html-proofer can't check
if [[ $(git diff-tree --no-commit-id --name-only -r HEAD |
               grep --invert-match --color=never -E \
                    -e '.*\.gitignore' \
                    -e '*\.yml'
        ) < "" ]]
then
    variable=$(cat <<EOF
Some files which html-proofer can't check were edited, exit successfully.
EOF
)
    success "$variable"
else
    notice "no changes in non-web or non-markdown files found"
fi


# -------------------------------------------------------------------------------


notice "Check for changed markdown files"

# run pandoc on every markdown file which was changed.
md_files=$(git diff-tree --no-commit-id --name-only -r HEAD |
         grep --color=never -E \
              -e '.*\.markdown' -e '.*\.md')

if [[  "$md_files" > "" ]]
then
    install_apt "pandoc"

    # jekyll is not needed, as we're only testing markdown files
    install_gem "html-proofer"


    echo "$md_files" | xargs "pandoc --from=markdown_github --write=html"

    # replaces markdown extensions with html and unrs html-proofer on it.
    html-proofer ${md_files%.(md|markdown)}.html

    if [[ ! $? -gt 0 ]]
    then
        success "checking markdown files successful"
    else
        fail "checking markdown files failed."
    fi

else
    notice "No changed markdown files have been found"
fi

echo "done."
exit 0
