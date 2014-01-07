

usage()
{
  echo ""
  echo ""
  echo "pulp-puppet-module-builder [options]"
  echo ""
  echo "Build puppet archives.
  echo ""
  echo ""Options:
  echo ""
  echo "-p --path        <path>   Path to a puppet module or a directory containing puppet"
  echo "                          modules to build.  Default: current directory."
  echo ""
  echo "-u --url         <url>    The URL to a git repository to be cloned. Repositories"
  echo "                          will be cloned into the current directory or the location"
  echo "                          specified by --path."
  echo ""
  echo "-b --branch      <branch> The name of a git branch to be checked out."
  echo ""
  echo "-t --tag         <tag>    The name of a git tag to be checked out."
  echo ""
  echo "-o --out-dir     <path>   The output location."
  echo ""
  echo "-r --recursive            Recursively process directories looking for puppet modules."
  echo ""
  echo "-c --clean                Delete cloned repositories after building."
  echo ""
}