#!/bin/bash
# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Script to switch CentOS (or other similar distribution) to the
# Oracle Linux yum repository.
#

set -e
unset CDPATH

yum_url=https://yum.oracle.com
contact_email=oraclelinux-info_ww_grp@oracle.com
bad_packages=(centos-backgrounds centos-logos centos-release centos-release-cr desktop-backgrounds-basic \
              libreport-centos libreport-plugin-mantisbt libreport-plugin-rhtsupport python3-syspurpose \
              python-oauth sl-logos yum-rhn-plugin)

usage() {
    echo "Usage: ${0##*/} [OPTIONS]"
    echo
    echo "OPTIONS"
    echo "-h"
    echo "        Display this help and exit"
    exit 1
} >&2

have_program() {
    hash "$1" >/dev/null 2>&1
}

dep_check() {
    if ! have_program "$1"; then
        exit_message "'${1}' command not found. Please install or add it to your PATH and try again."
    fi
}

exit_message() {
    echo "$1"
    echo "For assistance, please email <${contact_email}>."
    exit 1
} >&2

restore_repos() {
    yum remove -y "${new_releases[@]}"
    find . -name 'repo.*' | while read -r repo; do
        destination=$(head -n1 "$repo")
        if [ "${destination}" ]; then
            tail -n+2 "${repo}" > "${destination}"
        fi
    done
    rm "${reposdir}/${repo_file}"
    exit_message "Could not install Oracle Linux packages.
Your repositories have been restored to your previous configuration."
}

## Start of script

while getopts "h" option; do
    case "$option" in
        h) usage ;;
        *) usage ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    exit_message "You must run this script as root.
Try running 'su -c ${0}'."
fi

echo "Checking for required packages..."
for pkg in rpm yum curl; do
    dep_check "${pkg}"
done

echo "Checking your distribution..."
if ! old_release=$(rpm -q --whatprovides redhat-release); then
    exit_message "You appear to be running an unsupported distribution."
fi

if [ "$(echo "${old_release}" | wc -l)" -ne 1 ]; then
    exit_message "Could not determine your distribution because multiple
packages are providing redhat-release:
$old_release
"
fi

case "${old_release}" in
    redhat-release*) ;;
    centos-release* | centos-linux-release*) ;;
    sl-release*) ;;
    oraclelinux-release*|enterprise-release*)
        exit_message "You appear to be already running Oracle Linux."
        ;;
    *) exit_message "You appear to be running an unsupported distribution." ;;
esac

os_version=$(rpm -q "${old_release}" --qf "%{version}")
base_packages=(basesystem initscripts oracle-logos)
case "$os_version" in
    8*)
        repo_file=public-yum-ol8.repo
        new_releases=(oraclelinux-release oraclelinux-release-el8 redhat-release)
        base_packages=("${base_packages[@]}" plymouth grub2 grubby kernel-uek)
        ;;
    7*)
        repo_file=public-yum-ol7.repo
        new_releases=(oraclelinux-release oraclelinux-release-el7 redhat-release-server)
        base_packages=("${base_packages[@]}" plymouth grub2 grubby kernel-uek)
        ;;
    6*)
        repo_file=public-yum-ol6.repo
        new_releases=(oraclelinux-release oraclelinux-release-el6 redhat-release-server)
        base_packages=("${base_packages[@]}" oraclelinux-release-notes plymouth grub grubby kernel-uek)
        ;;
    *) exit_message "You appear to be running an unsupported distribution." ;;
esac

# Replace EPEL configuration, if it exists
if [ "$(rpm --quiet -q epel-release)" ]; then
    bad_packages+=(epel-release)
    new_releases+=("oracle-epel-release-el${old_version}")
fi


echo "Checking for yum lock..."
if [ -f /var/run/yum.pid ]; then
    yum_lock_pid=$(cat /var/run/yum.pid)
    yum_lock_comm=$(cat "/proc/${yum_lock_pid}/comm")
    exit_message "Another app is currently holding the yum lock.
The other application is: $yum_lock_comm
Running as pid: $yum_lock_pid
Run 'kill $yum_lock_pid' to stop it, then run this script again."
fi

echo "Checking for required python packages..."
case "$os_version" in
    8*)
        dep_check /usr/libexec/platform-python
        ;;
    *)
        dep_check python2
        ;;
esac

echo "Finding your repository directory..."
case "$os_version" in
    8*)
reposdir=$(/usr/libexec/platform-python -c "
import dnf
import os

dir = dnf.Base().conf.get_reposdir
if os.path.isdir(dir):
    print(dir)
")
        ;;
    *)
        reposdir=$(python2 -c "
import yum
import os

for dir in yum.YumBase().doConfigSetup(init_plugins=False).reposdir:
    if os.path.isdir(dir):
        print dir
        break
")
        ;;
esac

if [ -z "${reposdir}" ]; then
    exit_message "Could not locate your repository directory."
fi
cd "$reposdir"

# No https://yum.oracle.com/public-yum-ol8.repo file exists
# Download the content for 6 and 7 based systems and directly enter the content for 8 based systems
case "$os_version" in
    8*)
        cat > "switch-to-oraclelinux.repo" <<-'EOF'
		[ol8_baseos_latest]
		name=Oracle Linux 8 BaseOS Latest ($basearch)
		baseurl=https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/$basearch/
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
		gpgcheck=1
		enabled=1

		[ol8_appstream]
		name=Oracle Linux 8 Application Stream ($basearch)
		baseurl=https://yum.oracle.com/repo/OracleLinux/OL8/appstream/$basearch/
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
		gpgcheck=1
		enabled=1

		[ol8_UEKR6]
		name=Latest Unbreakable Enterprise Kernel Release 6 for Oracle Linux $releasever ($basearch)
		baseurl=https://yum.oracle.com/repo/OracleLinux/OL8/UEKR6/$basearch/
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
		gpgcheck=1
		enabled=1
EOF
        ;;
    *)
        echo "Downloading Oracle Linux yum repository file..."
        if ! curl -o "switch-to-oraclelinux.repo" "${yum_url}/${repo_file}"; then
            exit_message "Could not download $repo_file from $yum_url.
        Are you behind a proxy? If so, make sure the 'http_proxy' environment
        variable is set with your proxy address."
        fi
        ;;
esac


echo "Looking for yumdownloader..."
if ! have_program yumdownloader; then
    # CentOS 6 mirrors are now offline, if yumdownloader tool is not present then
    #  use OL6 as source for yum-utils and disable all other repos.
    # Use the existing distributions copy for other platforms
    case "$os_version" in
        6*)
            curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle https://yum.oracle.com/RPM-GPG-KEY-oracle-ol6
            yum -y install yum-utils --disablerepo \* --enablerepo ol6_latest || true
            ;;
        *)
            yum -y install yum-utils --disablerepo ol\* || true
            ;;
    esac
    dep_check yumdownloader
fi

cd "$(mktemp -d)"
trap restore_repos ERR

# Most distros keep their /etc/yum.repos.d content in the -release rpm. CentOS 8 does not and the behaviour changes between 
#  minor releases; 8.0 uses 'centos-repos' while 8.3 uses 'centos-linux-repos', glob for simplicity.
if [[ $old_release =~ ^centos-release-8.* ]] || [[ $old_release =~ ^centos-linux-release-8.* ]]; then
    old_release=$(rpm -qa centos*repos)
fi

echo "Backing up and removing old repository files..."
rpm -ql "$old_release" | grep '\.repo$' > repo_files
while read -r repo; do
    if [ -f "$repo" ]; then
        cat - "$repo" > "$repo".disabled <<EOF
# This is a yum repository file that was disabled by
# ${0##*/}, a script to convert CentOS to Oracle Linux.
# Please see $yum_url for more information.

EOF
        tmpfile=$(mktemp repo.XXXXX)
        echo "$repo" | cat - "$repo" > "$tmpfile"
        rm "$repo"
    fi
done < repo_files

echo "Downloading Oracle Linux release package..."
if ! yumdownloader "${new_releases[@]}"; then
    {
        echo "Could not download the following packages from $yum_url:"
        echo "${new_releases[@]}"
        echo
        echo "Are you behind a proxy? If so, make sure the 'http_proxy' environment"
        echo "variable is set with your proxy address."
    } >&2
    restore_repos
fi

echo "Switching old release package with Oracle Linux..."
rpm -i --force "${new_releases[@]/%/*.rpm}"
rpm -e --nodeps "$old_release"
rm -f "${reposdir}/switch-to-oraclelinux.repo"

# At this point, the switch is completed.
trap - ERR

echo "Installing base packages for Oracle Linux..."
if ! yum shell -y <<EOF
remove ${bad_packages[@]}
install ${base_packages[@]}
run
EOF
then
    exit_message "Could not install base packages.
Run 'yum distro-sync' to manually install them."
fi
if [ -x /usr/libexec/plymouth/plymouth-update-initrd ]; then
    echo "Updating initrd..."
    /usr/libexec/plymouth/plymouth-update-initrd
fi

echo "Switch successful. Syncing with Oracle Linux repositories."

if ! yum -y distro-sync; then
    exit_message "Could not automatically sync with Oracle Linux repositories.
Check the output of 'yum distro-sync' to manually resolve the issue."
fi

# CentOS specific replacements
case "$os_version" in
    7*)
        # Prior to switch this is a dependancy of the yum rpm, now we've switched we can remove it
        if rpm -q yum-plugin-fastestmirror; then
            yum erase -y yum-plugin-fastestmirror
        fi
        ;;
    8*)
        # There are a few dnf modules that are named after the distribution
        #  for each steam named 'rhel' or 'rhel8' perform a module reset and install
        modules_enabled=($(dnf module list --enabled | grep rhel | cut -f1 -d\  ))
        if [[ "${modules_enabled[@]}" ]]; then
            for module in "${modules_enabled[@]}"; do
                dnf module reset -y "${module}"
                case ${module} in
                container-tools|go-toolset|jmc|llvm-toolset|rust-toolset)
                    dnf module install -y "${module}":ol8
                    ;;
                virt)
                    dnf module install -y "${module}":ol
                    ;;
                *)
                    echo "Unsure how to transform module ${module}"
                    ;;
                esac
            done
            dnf update -y --disablerepo "*" --enablerepo "ol8_appstream"
        fi

        # Two logo RPMs aren't currently covered by 'replaces' metadata, replace by hand.
        if rpm -q centos-logos-ipa; then
            dnf swap -y centos-logos-ipa oracle-logos-ipa
        fi
        if rpm -q centos-logos-httpd; then
            dnf swap -y centos-logos-httpd oracle-logos-httpd
        fi
        ;;
esac

echo "Sync successful. Switching default kernel to the UEK."

arch=$(uname -m)
uek_path=$(find /boot -name "vmlinuz-*.el${os_version}uek.${arch}")

case "$os_version" in
    7* | 8*)
        # Installing current latest kernel-uek on current latest CentOS 8.3 will
        #  cause a dracut coredump during the posttrans scriptlet leaving a system unbootable.
        #  Cause not investigated but for a temporary workaround, reinstall kernel-uek now that we have OL userland
        yum reinstall -y kernel-uek
        if [ -d /sys/firmware/efi ]; then
            grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        else
            grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
        grubby --set-default="${uek_path}"
        ;;
    6*)
        grubby --set-default="${uek_path}"
        ;;
esac

echo "Removing yum cache"
yum clean all

echo "Switch complete. Oracle recommends rebooting this system."