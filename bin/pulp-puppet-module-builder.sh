#!/bin/bash

set -e  # exit on failed

PULP_MANIFEST="pulp_manifest"


print_usage()
{
cat << EOF
usage: $0 options

Build puppet archives.

OPTIONS:

  -p <path>   Path to a puppet module or a directory containing puppet
              modules to build.  Default: working directory.
  
  -u <url>    The URL to a git repository to be cloned. Repositories
              will be cloned into the current directory or the location
              specified by --path.
  
  -b <branch> The name of a git branch to be checked out.
  
  -t <tag>    The name of a git tag to be checked out.

  -w <dir>    The working directory used for git cloning.  Default: current directory.
  
  -o <dir>    The output location.
  
  -r          Recursively process directories looking for puppet modules.
  
  -c          Delete cloned repositories after building.
EOF
}


read_options()
{
  opt_path=$PWD
  opt_url=""
  opt_branch=""
  opt_tag=""
  opt_working_dir=opt_path
  opt_out_dir=$opt_path
  opt_recursive=""
  opt_clean=""

  while getopts "hrcp:u:b:t:w:o:" OPTION $1
  do
    case $OPTION in
      h)
        print_usage
        exit 1
        ;;
      p)
        opt_path=$OPTARG
        ;;
      u)
        opt_url=$OPTARG
        ;;
      b)
        opt_branch=$OPTARG
        ;;
      t)
        opt_tag=$OPTARG
        ;;
      w)
        opt_working_dir=$OPTARG
        ;;
      o)
        opt_out_dir=$OPTARG
        ;;
      r)
        opt_recursive=1
        ;;
      c)
        opt_clean=1
        ;;
      ?)
        print_usage
        exit
        ;;
    esac
  done
}

find_git_origin()
{
  set +e
  git status &> /dev/null
  if [ $? -ne 0 ]
  then
    # not in a git repository
    return
  fi
  git_url=$(git remote show -n origin | grep Fetch | cut -d: -f2-)
  origin=$(basename $git_url)
  echo $origin
  set -e
}

git_clone()
{
  if [[ -n $opt_url ]]
  then
    pushd $opt_working_dir
    git clone $opt_url
    repository=$(basename $opt_url)
    popd
  fi
}

git_checkout()
{
  if [[ -z $origin ]]
  then
    # not in a repository
    return
  fi

  git fetch && git fetch --tags

  if [[ -n $opt_branch ]]
  then
    git checkout $opt_branch
  fi

  if [[ -n $opt_tag ]]
  then
    git checkout $opt_tag
  fi

  git pull
}

build_puppet_modules()
{
  echo "building puppet modules"
  for path in $(find . -name init.pp)
  do
    path=$(dirname $path)
    name=$(basename $path)
    if [ "$name" == "manifests" ]
    then
      path=$(dirname $path)
      echo "puppet module build : $path"
    fi
  done
}

build_manifest()
{
  echo "building manifest"
  pushd $opt_out_dir
  rm -f $PULP_MANIFEST
  for path in $(find . -name \*.tar.gz)
  do
    hash=($(sha256sum $path))
    size=$(stat -c%s $path)
    entry="$path,${hash[0]},$size"
    echo $entry >> $PULP_MANIFEST
  done
  popd
}

main()
{
  cd $opt_path
  git_clone
  find_git_origin
  git_checkout
  build_puppet_modules
  build_manifest
}

read_options "$*"
main
