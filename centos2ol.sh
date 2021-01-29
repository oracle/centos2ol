#!/bin/bash
# Copyright (c) 2020-2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Script to switch CentOS (or other similar distribution) to the Oracle Linux yum repository.
# with better diagnistics output formatting and restore_repos function converted to a dummy. 
# 1.00  oracle  2020/12/28  Oracle initial implementation
# 2.00  bezroun 2021/01/07  Some cosmetic changes and better diagnistic 


set -e
unset CDPATH
declare VERSION='2.00'
declare BASE='/tmp/Centos2ol'
declare -i STEPNO=0
declare -i STARTNO=0

 
yum_url=https://yum.oracle.com
github_url=https://github.com/oracle/centos2ol/
bad_packages=(centos-backgrounds centos-logos centos-release centos-release-cr desktop-backgrounds-basic \
              centos-release-advanced-virtualization centos-release-ansible26 centos-release-ansible-27 \
              centos-release-ansible-28 centos-release-ansible-29 centos-release-azure \
              centos-release-ceph-jewel centos-release-ceph-luminous centos-release-ceph-nautilus \
              centos-release-ceph-octopus centos-release-configmanagement centos-release-dotnet centos-release-fdio \
              centos-release-gluster40 centos-release-gluster41 centos-release-gluster5 \
              centos-release-gluster6 centos-release-gluster7 centos-release-gluster8 \
              centos-release-gluster-legacy centos-release-messaging centos-release-nfs-ganesha28 \
              centos-release-nfs-ganesha30 centos-release-nfv-common \
              centos-release-nfv-openvswitch centos-release-openshift-origin centos-release-openstack-queens \
              centos-release-openstack-rocky centos-release-openstack-stein centos-release-openstack-train \
              centos-release-openstack-ussuri centos-release-opstools centos-release-ovirt42 centos-release-ovirt43 \
              centos-release-ovirt44 centos-release-paas-common centos-release-qemu-ev centos-release-qpid-proton \
              centos-release-rabbitmq-38 centos-release-samba411 centos-release-samba412 \
              centos-release-scl centos-release-scl-rh centos-release-storage-common \
              centos-release-virt-common centos-release-xen centos-release-xen-410 \
              centos-release-xen-412 centos-release-xen-46 centos-release-xen-48 centos-release-xen-common \
              libreport-centos libreport-plugin-mantisbt libreport-plugin-rhtsupport python3-syspurpose \
              python-oauth sl-logos yum-rhn-plugin)

function step_info
{
STEPNO++
   echo
   echo
   echo "============================================================================"
   echo "*** Step $STEP_NO, starting at LINE $1: $2"
   echo "============================================================================"
   if (( STARTNO > 0 && STEPNO < STARTNO )); then 
      echo
      echo "=== STEP SKIPPED ==="
      echo
   fi  
      
   echo $STEPNO > $BASE/laststep
   if (( debug )); then 
     answer='y'
     echo "Continue ? (Enter or Y to continue, A to abort, integer -- skip to the given step)." 
     read answer
     if [[ $answer =~ [Aa] ]]; then
        exit 1
     fi
     if  (( answer > 0 )) ; then
         STARTNO=$answer;
         echo Continuing with the step $answer 
         return;
     fi 
   else
     sleep 3
   fi     
}

function info
{
   echo 
   echo "INFO-$1: $2"
   echo
   sleep 3    
}

function abend
{
   echo
   echo "============================================================================"
   echo " !!! Fatal error at line $1: $2"
   echo "For assistance, please open an issue via GitHub: ${github_url}."
   echo "============================================================================"
   echo
       
}

usage() {
    echo "Usage: ${0##*/} [OPTIONS]"
    echo
    echo "OPTIONS"
    echo "-h"
    echo "        Display this help and exit"
    echo "-d"
    echo "        Switch to debugging mode with confirmation for each step"
    echo "-r"
    echo "        Reinstall all CentOS RPMs with Oracle Linux RPMs"
    echo "        Note: This is not necessary for support"
    exit 1
} >&2

have_program() {
    hash "$1" >/dev/null 2>&1
}

dep_check() {
    if ! have_program "$1"; then
        abend $LINENO "'${1}' command not found. Please install or add it to your PATH and try again."
    fi
}

error_handler1() {
   abend $LINENO "Error condition intercepted. Could not install Oracle Linux packages."
}

error_handler2(){
   abend $LINENO "Error during execution of yum shell commands."
}
function data_dump
{
   if (( debug )); then 
      echo "=== DATA DUMP ==="
      cat $BASE/data_dump
      echo "================="
   fi      
}

## Start of the script
if (( $(id -u) > 0 )); then
   abend $LINENO "You must run this script as root. You can try running sudo $0  or su -c $0 , if you want to start it from a regular account"
fi

if [[ -d $BASE ]]; then 
   info $LINENO "ATTENTION: the directory BASE exists, so we assume that you are re-rerunning the conversion after an error"
   if [[ -f $BASE/data_dump ]]; then 
      if [[ ! -f $BASE/laststep ]]; then 
         abend $LINENO "File $BASE/laststep does not exists"
      fi
      . $BASE/data_dump
      STARTNO=`cat $BASE/laststep`
      info $LINENO "ATTENTION: Attempting to continue from step $STARNO. If you want a different step please correct $BASE/laststep and re-run the script" 
      echo "Correct execution is not garanteered. You can cancel the script within the next 10 sec "
      sleep 10
   else
      mkdir -p BASE
      if [[ ! -d $BASE ]]; then 
         abend $LINENO "Can't create the directory $BASE"
      fi   
   fi  
fi
  
reinstall_all_rpms=false

while getopts "h:r" option; do
    case "$option" in
        h) usage ;;
        d) debug=1;;
        r) reinstall_all_rpms=true ;;
        *) usage ;;
    esac
done

step_info $LINENO "Checking for required packages..."
if (( STEPNO >= STARTNO  )) ; then
   for pkg in rpm yum curl; do
       dep_check "${pkg}"
   done
fi

step_info $LINENO "Checking your distribution..."
if (( STEPNO >= STARTNO  )) ; then
   if ! old_release=$(rpm -q --whatprovides redhat-release); then
       abend $LINENO "You appear to be running an unsupported distribution."
   fi

   if (( "$(echo "${old_release}" | wc -l)" != 1 )); then
       abend $LINENO "Could not determine your distribution because multiple packages are providing redhat-release:
   $old_release
   "
   fi

   case "${old_release}" in
       redhat-release*) ;;
       centos-release* | centos-linux-release*) ;;
       sl-release*) ;;
       oraclelinux-release*|enterprise-release*)
           abend $LINENO "You appear to be already running Oracle Linux."
           ;;
       *) abend $LINENO "You appear to be running an unsupported distribution." ;;
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
       *) abend $LINENO "You appear to be running an unsupported distribution." ;;
   esac
   echo "old_release=$old_release">> $BASE/data_dump
   echo "new_releases=( ${new_releases[@]} )" >> $BASE/data_dump
   echo "repo_file='$repo_file'"  >> $BASE/data_dump 
   echo "os_version='$os_version" >> $BASE/data_dump
   echo "base_packages=( ${base_packages[@]} )" >> $BASE/data_dump 
   data_dump      
fi

step_info $LINENO "Replace EPEL configuration, if it exists"
if (( STEPNO >= STARTNO  )) ; then
   if [ "$(rpm --quiet -q epel-release)" ]; then
       bad_packages+=(epel-release)
       new_releases+=("oracle-epel-release-el${old_version}")
   fi
   echo "new_releases=( ${new_releases[@]} )" >> $BASE/data_dump
   echo "bad_packages=( ${bad_packages[@]} )" >> $BASE/data_dump
fi 

step_info $LINENO "Checking for yum lock..."
if [ -f /var/run/yum.pid ]; then
    yum_lock_pid=$(cat /var/run/yum.pid)
    yum_lock_comm=$(cat "/proc/${yum_lock_pid}/comm")
    abend $LINENO "Another app is currently holding the yum lock.
The other application is: $yum_lock_comm
Running as pid: $yum_lock_pid
Run 'kill $yum_lock_pid' to stop it, then run this script again."
fi

step_info $LINENO "Checking for required python packages..."
case "$os_version" in
    8*)
        dep_check /usr/libexec/platform-python
        ;;
    *)
        dep_check python2
        ;;
esac

if [[ "$os_version" =~ 8.* ]]; then
    echo "Identifying dnf modules that are enabled"
    # There are a few dnf modules that are named after the distribution
    #  for each steam named 'rhel' or 'rhel8' we need to make alterations to 'ol' or 'ol8'
    #  Before we start the switch, identify if there are any present we don't know how to handle
    mapfile -t modules_enabled < <(dnf module list --enabled | grep rhel | awk '{print $1}')
    if [[ "${modules_enabled[*]}" ]]; then
        # Create an array of modules we don't know how to manage
        unknown_modules=()
        for module in "${modules_enabled[@]}"; do
            case ${module} in
                container-tools|go-toolset|jmc|llvm-toolset|rust-toolset|virt)
                    ;;
                *)
                    # Add this module name to our array of modules we don't know how to manage
                    unknown_modules+=("${module}")
                    ;;
            esac
        done
        # If we have any modules we don't know how to manage, ask the user how to proceed
        if (( ${#unknown_modules[@]} > 0 )); then
            echo "This tool is unable to automatically switch module(s) '${unknown_modules[*]}' from a CentOS 'rhel' stream to
an Oracle Linux equivalent. Do you want to continue and resolve it manually?
You may want select No to stop and raise an issue on ${github_url} for advice."
            select yn in "Yes" "No"; do
                case $yn in
                    Yes )
                        break
                        ;;
                    No )
                        echo "Unsure how to switch module(s) '${unknown_modules[*]}'. Exiting as requested"
                        exit 1
                        ;;
                esac
            done
        fi
    fi
fi

step_info $LINENO "Finding your repository directory..."
if (( STEPNO >= STARTNO  )) ; then
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

   step_info $LINENO "Learning which repositories are enabled..."
   case "$os_version" in
       8*)
           enabled_repos=$(/usr/libexec/platform-python -c "
   import dnf

   base = dnf.Base()
   base.read_all_repos()
   for repo in base.repos.iter_enabled():
     print(repo.id)
   ")
           ;;
       *)
           enabled_repos=$(python2 -c "
   import yum

   base = yum.YumBase()
   base.doConfigSetup(init_plugins=False)
   for repo in base.repos.listEnabled():
     print repo
   ")
           ;;
   esac

   echo -e "Repositories enabled before update include:\n${enabled_repos}"

   if [ -z "${reposdir}" ]; then
       abend $LINENO "Could not locate your repository directory."
   fi
   echo "enabled_repos=$enabled_repos">> $BASE/data_dump
   echo "reposdir=$reposdir">> $BASE/data_dump
   data_dump
fi

cd "$reposdir"

# No https://yum.oracle.com/public-yum-ol8.repo file exists
# Download the content for 6 and 7 based systems and directly enter the content for 8 based systems
step_info $LINENO "Download the content for 6 and 7 based systems and directly enter the content for 8 based systems"
if (( STEPNO >= STARTNO  )) ; then
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
               abend $LINENO "Could not download $repo_file from $yum_url.
           Are you behind a proxy? If so, make sure the 'http_proxy' environment
           variable is set with your proxy address."
           fi
           ;;
   esac
fi

step_info $LINENO "Looking for yumdownloader..."
if (( STEPNO >= STARTNO  )) ; then
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
fi
step_info $LINENO "Creating temporary directory for files"
if (( STEPNO >= STARTNO  )) ; then
   #cd "$(mktemp -d)"
   mkdir $BASE/temp
fi
   
cd $BASE/temp

if (( STEPNO >= STARTNO  )) ; then
# Most distros keep their /etc/yum.repos.d content in the -release rpm. CentOS 8 does not and the behaviour changes between
#  minor releases; 8.0 uses 'centos-repos' while 8.3 uses 'centos-linux-repos', glob for simplicity.

if [[ $old_release =~ ^centos-release-8.* ]] || [[ $old_release =~ ^centos-linux-release-8.* ]]; then
    old_release=$(rpm -qa centos*repos)
fi
fi

step_info $LINENO "Backing up and removing old repository files..."
# Identify repo files from the base OS and write them to $BASE/temp/repo_files
if (( STEPNO >= STARTNO  )) ; then
   rpm -ql "$old_release" | grep '\.repo$' > repo_files
   # Identify repo files from 'CentOS extras'
   if [ "$(rpm -qa "centos-release-*" | wc -l)" -gt 0 ] ; then
       rpm -qla "centos-release-*" | grep '\.repo$' >> repo_files
   fi
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
fi

step_info $LINENO "Downloading Oracle Linux release package..."
if (( STEPNO >= STARTNO  )) ; then
   trap error_handler1 ERR
   if ! yumdownloader "${new_releases[@]}"; then
       {
           echo "Could not download the following packages from $yum_url:"
           echo "${new_releases[@]}"
           echo
           echo "Are you behind a proxy? If so, make sure the 'http_proxy' environment"
           echo "variable is set with your proxy address."
       } >&2
       abend $1 "Error in executing yumdowloader"
   fi
   trap - ERR
fi

step_info $LINENO "Switching old release package with Oracle Linux..."
if (( STEPNO >= STARTNO  )) ; then
   rpm -i --force "${new_releases[@]/%/*.rpm}"
   rpm -e --nodeps "$old_release" 
   rm -f "${reposdir}/switch-to-oraclelinux.repo"
fi

step_info $LINENO "At this point, the switch is completed as the release is switched. Change CentOs repo to matching Oracle repo files"
if (( STEPNO >= STARTNO  )) ; then
# When an additional enabled CentOS repository has a match with Oracle Linux
#  then automatically enable the OL repository to ensure the RPM is maintained
#
# Create an associate array where the key is the CentOS reponame and the value
#  contains the method of getting the content (Enable a repo or install an RPM)
#  and the details of the repo or RPM
   case "$os_version" in
       6*)
           declare -A repositories=(
               [base-debuginfo]="REPO https://oss.oracle.com/ol6/debuginfo/"
               [updates]="REPO ol6_latest"
           )
           ;;
       7*)
           declare -A repositories=(
               [base-debuginfo]="REPO https://oss.oracle.com/ol7/debuginfo/"
               [updates]="REPO ol7_latest"
               [centos-ceph-jewel]="RPM oracle-ceph-release-el7"
               [centos-gluster41]="RPM oracle-gluster-release-el7"
               [centos-gluster5]="RPM oracle-gluster-release-el7"
               [centos-gluster46]="RPM oracle-gluster-release-el7"
               [centos-nfs-ganesha30]="RPM oracle-gluster-release-el7"
               [centos-ovirt42]="RPM oracle-ovirt-release-el7"
               [centos-ovirt43]="RPM oracle-ovirt-release-el7"
               [centos-sclo-sclo]="RPM oracle-softwarecollection-release-el7"
               [centos-sclo-rh]="RPM oracle-softwarecollection-release-el7"
           )
           ;;
       8*)
           declare -A repositories=(
               [AppStream]="REPO ol8_appstream"
               [BaseOS]="REPO ol8_baseos_latest"
               [HighAvailability]="REPO ol8_addons"
               [PowerTools]="REPO ol8_codeready_builder"
               [centos-release-nfs-ganesha28]="RPM oracle-gluster-release-el8"
               [centos-gluster6-test]="RPM oracle-gluster-release-el8"
               [centos-gluster7]="RPM oracle-gluster-release-el8"
               [centos-gluster8]="RPM oracle-gluster-release-el8"
           )
           ;;
   esac

   # For each entry in the list, enable it
   for reponame in ${enabled_repos}; do
       # action[0] will be REPO or RPM
       # action[1] will be the repos details or the RPMs name
       IFS=" " read -r -a action <<< "${repositories[${reponame}]}"
       if [[ -n ${action[0]} ]]; then
           if [ "${action[0]}" == "REPO" ] ; then
               matching_repo=${action[1]}
               echo "Enabling ${matching_repo} which replaces ${reponame}"
               # An RPM that describes debuginfo repository does not exist
               #  check to see if the repo id starts with https, if it does then
               #  create a new repo pointing to the repository
               if [[ ${matching_repo} =~ https.* ]]; then
                   yum-config-manager --add-repo "${matching_repo}"
               else
                   yum-config-manager --enable "${matching_repo}"
               fi
           elif [ "${action[0]}" == "RPM" ] ; then
               matching_rpm=${action[1]}
               echo "Installing ${matching_rpm} to get content that replaces ${reponame}"
               yum --assumeyes --disablerepo "*" --enablerepo "ol*_latest" install "${matching_rpm}"
           fi
       fi
   done
fi

step_info $LINENO "Installing base packages for Oracle Linux..."
if (( STEPNO >= STARTNO  )) ; then
   trap error_handler2 ERR
   if ! yum shell -y <<EOF
remove ${bad_packages[@]}
install ${base_packages[@]}
run
EOF
   then
       abend $LINENO "Could not install base packages. Run 'yum distro-sync' to manually install them."
   fi
   trap - ERR
fi

step_info $LINENO "Updating initrd..."
if (( STEPNO >= STARTNO  )) ; then
   if [ -x /usr/libexec/plymouth/plymouth-update-initrd ]; then       
      /usr/libexec/plymouth/plymouth-update-initrd
   else
      info $LINENO "Step skipped as /usr/libexec/plymouth/plymouth-update-initrd is not executable. May be not installed. Please investigate"
   fi
fi

step_info $LINENO "Switch successful. Syncing with Oracle Linux repositories."
if (( STEPNO >= STARTNO  )) ; then
   if ! yum -y distro-sync; then
       abend $LINENO "Could not automatically sync with Oracle Linux repositories.
Check the output of 'yum distro-sync' to manually resolve the issue. Do not try to rerun the script"
   fi
fi

# CentOS specific replacements
step_info $LINENO "CentOS specific replacements"
if (( STEPNO >= STARTNO  )) ; then
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
           if [[ "${modules_enabled[*]}" ]]; then
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
               dnf --assumeyes --disablerepo "*" --enablerepo "ol8_appstream" update
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
fi

step_info $LINENO "Reinstall all RPMS"
if (( STEPNO >= STARTNO  )) ; then
   if "${reinstall_all_rpms}"; then
       echo "Testing for remaining CentOS RPMs"
       # If CentOS and Oracle Linux have identically versioned RPMs then those RPMs are left unchanged.
       #  This should have no technical impact but for completeness, reinstall these RPMs
       #  so there is no accidental cross pollination.
       mapfile -t list_of_centos_rpms < <(rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE} %{VENDOR}\n" | grep CentOS | awk '{print $1}')
       if [[ -n "${list_of_centos_rpms[*]}" ]]; then
           echo "Reinstalling RPMs: ${list_of_centos_rpms[*]}"
           yum --assumeyes --disablerepo "*" --enablerepo "ol*" reinstall "${list_of_centos_rpms[@]}"
       fi
       # See if non-Oracle RPMs are present and print them
       mapfile -t non_oracle_rpms < <(rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE}|%{VENDOR}|%{PACKAGER}\n" |grep -v Oracle)
       if [[ -n "${non_oracle_rpms[*]}" ]]; then
           echo "The following non-Oracle RPMs are installed on the system:"
           printf '\t%s\n' "${non_oracle_rpms[@]}"
           echo "This may be expected of your environment and does not necessarily indicate a problem."
           echo "If a large number of CentOS RPMs are included and you're unsure why please open an issue on ${github_url}"
       fi
   else
      info $LINENO "Step skipped"
   fi
fi
  
step_info $LINENO "Yum repo sync successful. Switching default kernel to the UEK."
if (( STEPNO >= STARTNO  )) ; then
   arch=$(uname -m)
   uek_path=$(find /boot -name "vmlinuz-*.el${os_version}uek.${arch}")
   if [[ ! -f uek_path ]]; then
      abend $LINENO "Can't find UEK kernel. Please locate UEK kernel manually and execute appropriate command to make it the default"
   fi      
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
fi

step_info $LINENO "Removing yum cache"
rm -rf /var/cache/{yum,dnf}

info $LINENO "Switch complete. Oracle recommends rebooting this system."