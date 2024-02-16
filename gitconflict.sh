#!/bin/bash

#set -x
file=$1

if [ ! -z $file ]; then
  echo "Process $file"
else
  echo "Please specify a file"
  exit 1
fi

#git log --follow --name-only --stat-width=1000 --format='%h' $file | grep -Pzo '[0-9a-f]*\n.*\n.*\n'
#git log --follow --name-only --stat-width=1000 --format='%h' $file | sed -e 's/^\([0-9a-f]\{8\}$\)/boz\1gor/'

declare -A fileCommits

#git log --follow --name-only --stat-width=1000 --format='%h' $file | sed '{N;N} ; s/^\([0-9a-f]\{8\}\)\n\n\(.*\)/["\1"]="\2"/'

fileGitLog=$(git log --follow --name-only --stat-width=1000 --format='%h' $file)

fileGitLogClean=$(echo "$fileGitLog" | sed '{N;N} ; s/^\([0-9a-f]\+\)\n\n\(.*\)/\1|\2/')

#echo "$fileGitLogClean"

fileHashes=($(echo "$fileGitLogClean" | grep -o '^[^\|]*'))

eval declare -A hashPathLookup=( $(echo "$fileGitLogClean" | sed 's/^\([0-9a-f]\+\)|\(.*\)/["\1"]="\2"/') )

# Show commit hashes for the file
#echo ${fileHashes[@]}

#echo ${!hashPathLookup[@]}
#echo ${hashPathLookup[@]}

#exit 0

function getHash() {
  echo $(git rev-parse --git-path $1 | xargs cat | xargs git rev-parse --short)
}

if [ ! -f $(git rev-parse --git-path REBASE_HEAD) ]; then
  echo "Rebase not found"
  exit 1
fi

# This is where the conflict is
current=$(getHash 'REBASE_HEAD')
onto=$(getHash 'rebase-merge/onto')
base=$(git merge-base $current $onto | xargs git rev-parse --short)
echo "current	$current"
echo "onto	$onto"
echo "base	$base"

allCommits=($(git log --format='%h' $(git rev-parse --show-toplevel)))

#echo ${allCommits[@]}

fileHashIndex=0

for i in "${!allCommits[@]}"; do
  curHash=${allCommits[$i]}
  curFileHash=${fileHashes[$fileHashIndex]};
  # echo "curHash $curHash curFileHash $curFileHash"
  if [ "$curHash" = "$base" ]; then
    echo "Found base $curHash"
    foundBase=true
  fi
  if [ "$curHash" = "$curFileHash" ]; then
    #echo "Found hash $curFileHash"
    if [ "$foundBase" = true ]; then
      lookupHash=$curFileHash
      break
    fi
    fileHashIndex=$fileHashIndex+1
  fi
done

if [[ ! -v foundBase ]]; then
  echo "Base not found"
  exit 1
fi

if [[ ! -v lookupHash ]]; then
  echo "LookupHash not found"
  exit 1
fi

echo "LookupHash $lookupHash"

basePathName=${hashPathLookup[$lookupHash]}

echo "basePathName $basePathName"

#exit 0

#Assume name was unchanged between base and branch
# use 
#git log $base..$onto --follow --name-only --stat-width=1000 --format='%h' -- $basePathName

git difftool --no-prompt $current^! -- $basePathName &
git difftool --no-prompt $base:$basePathName $onto:$file &
#git difftool $current $file &
