#!/bin/bash


print_usage()
{
cat << EOF
usage: $0 options

Build puppet archives.

OPTIONS:

  -p <path>   Path to a puppet module or a directory containing puppet
              modules to build.  Default: current directory.
  
  -u <url>    The URL to a git repository to be cloned. Repositories
              will be cloned into the current directory or the location
              specified by --path.
  
  -b <branch> The name of a git branch to be checked out.
  
  -t <tag>    The name of a git tag to be checked out.
  
  -o <dir>    The output location.
  
  -r          Recursively process directories looking for puppet modules.
  
  -c          Delete cloned repositories after building.
EOF
}


read_options()
{
  opt_path=""
  opt_url=""
  opt_branch=""
  opt_tag=""
  opt_out_dir=""
  opt_recursive=""
  opt_clean=""

  echo "get options"

  while getopts "hrcp:u:b:t:o:" OPTION $1
  do
    echo "option: $OPTION"
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

read_options "$*"

echo $opt_path
