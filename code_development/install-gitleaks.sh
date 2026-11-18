#!/bin/bash
#title          : install-gitleaks.sh
#description    : Installs Gitleaks to a specified path. The latest version is
#                 installed unless indicated otherwise.
#author         : Jarrod N. Bakker
#date           : 19/11/2026
#version        : 0.1.0
#usage          : See disaply_usage() function below.
#history        : 19/11/2026 - jb - Draft version complete.
#===============================================================================
set -eo pipefail # A defensive measure to ensure that the script fails if curl
                 # fails to download resources

display_usage() {
    cat <<HELP_USAGE
Usage: $0 -h install_dir [tool_version]

Installs Gitleaks to a specified path. The latest version is installed unless
indicated otherwise.

Required:
  install_dir   The directory to install the tool to.

Optional:
  tool_version  Use the latest version of Gitleaks by default, this can be
                overridden by pinning to a specific version e.g. X.Y.Z
                (available versions are listed at https://github.com/gitleaks/gitleaks/releases,
                remove the leading 'v')

Options:
  -h        Display this message and exit    
HELP_USAGE
}

log_fatal() {
    echo -e "`date '+%Y-%m-%d %H:%M:%S'` FATAL $1"
}

log_info() {
    echo -e "`date '+%Y-%m-%d %H:%M:%S'` INFO $1"
}

# Thanks to https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f
# for the options parser below!
PARAMS=""
while (( "$#" )); do
    case "$1" in
        -h)
            display_usage
            exit 0
            ;;
        -*|--*=) # unsupported flags
            echo "Unsupported flag supplied: $1" >&2
            display_usage
            exit 1
            ;;
        *) # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
    esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

readonly install_dir=$1
readonly tool_name="gitleaks"
readonly tool_version="${2:-latest}"

if [[ -f "${install_dir}/${tool_name}" ]]; then
    log_info "An existing installation of '${tool_name}' has been found and "\
"it will be replaced."
fi

if [[ ! -d "${install_dir}" ]]; then
    log_fatal "Provided installation directory is invalid. Exiting..."
    exit 1
fi

version=""
if [[ "${tool_version}" == "latest" ]]; then
    version=$(curl -s "https://api.github.com/repos/gitleaks/gitleaks/releases/latest" | \
grep -Po '"tag_name": "v\K[0-9.]+')
else
    version="${tool_version}"
fi

log_info "Attempting to download and install '${tool_name}' version "\
"'${tool_version}'..."
wget "https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_linux_x64.tar.gz"
tar -xzf "gitleaks_${version}_linux_x64.tar.gz" "${tool_name}"
mv "${tool_name}" "${install_dir}"
chmod 700 "${install_dir}"/"${tool_name}"

log_info "Testing the '${tool_name}' binary..."
"${install_dir}"/"${tool_name}" --version

log_info "Removing downloaded .tar.gz file..."
rm "gitleaks_${version}_linux_x64.tar.gz"
