#!/bin/bash

BRANCH="HEAD"
TOOL="difftool"
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -b | --branch)
        BRANCH="$2"
        shift # past argument
        shift # past value
        ;;
    -t | --tool)
        TOOL="$2"
        shift # past argument
        shift # past value
        ;;
    *)                     # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift              # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "BRANCH          = ${BRANCH}"

git show ${BRANCH}~$1 --format='format:%d %Cgreen%h%Creset %ai %ci %an - %s' -s
git ${TOOL} ${BRANCH}~$1^! --name-only
git ${TOOL} ${BRANCH}~$1^! $2
