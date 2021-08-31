# Switch from CentOS to Oracle Linux

This script is designed to automatically switch a CentOS instance to Oracle Linux
by removing any CentOS-specific packages or replacing them with the Oracle Linux
equivalent.

## Supported versions and architectures

This script currently supports switching CentOS Linux 6, CentOS Linux 7 and
CentOS Linux 8 on both `x86_64` and `aarch64` architectures. It does **not** support CentOS Stream.

> Support for switching `aarch64` hosts should be considered **experimental**
> due to limited testing. Please ensure you have a **complete _working_ backup** before attempting
> to switch and [report any issues][6] you encounter during the process.

## Before you start

**IMPORTANT:** this script is a work-in-progress and is not designed to handle
all possible configurations. Please ensure you have a **complete working backup**
of the system _before_ you start this process in the event the script is unable to
convert the system successfully or unable to rollback the changes it made.

### Remove all non-standard kernels

Because of the [GRUB2 BootHole][1] vulnerability, our SecureBoot shim can
only boot kernels signed by Oracle and we can only replace the default
CentOS kernels. While this may not have an impact if SecureBoot is currently
disabled, enabling it at a later date could render the system unbootable.
For that reason, we strongly recommend removing all non-standard kernels, i.e.
any kernel that is installed that is _not_ provided by either the `base` or
`updates` repo. This includes the [`centosplus`][2] kernels.

1. Ensure your CentOS `yum` or `dnf` configuration is working, i.e. there are no
   stale repositories.
1. Disable all non-CentOS repositories. You can re-enable the repos after the switch.
1. Ensure you have at least 5GB of free space in `/var/cache`.
1. All automatic updates, e.g. via `yum-cron` should be disabled.

## Usage

1. Login to your CentOS Linux 6, 7 or 8 instance as a user who has `sudo` privileges.
1. Either clone this repository or download the [`centos2ol.sh`][3] script.
1. Run `sudo bash centos2ol.sh` to switch your CentOS instance to Oracle Linux.

### Usage options

* `-r` Reinstalls all CentOS RPMs with Oracle Linux RPMs

   If a system is switched to Oracle Linux and there is no newer Oracle Linux version
   of a package already installed then the CentOS version remains.
   This option proceeds to reinstall any CentOS RPM with an identical version from
   Oracle Linux. This is not necessary for support and has no impact to a systems functionality
   but is offered so a user can remove CentOS GPG keys from the truststore.
   A list of all non-Oracle RPMs will be displayed after the reinstall process.

* `-k` Do not install the UEK kernel and disable UEK repos

  This option will not install the UEK kernel and will disable all UEK yum repositories.

* `-V` Verify RPM information before and after the switch

  This option creates four output files in `/var/tmp/`:

  * `${hostname}-rpms-list-[before|after].log`: a sorted list of installed
    packages `before` and `after` the switch to Oracle Linux.
  * `${hostname}-rpms-verified-[before|after].log`: the RPM verification results
     for all installed packages `before` and `after` the switch to Oracle Linux.

## Testing

See [`TESTING.md`](./TESTING.md) for instructions on the available tests and
how to run them.

## Known issues

1. There is a [reported issue with the upstream OpenJDK][9] package resetting the
   `alternatives` configuration during a `dnf reinstall` transaction.

   We recommend recording the output of `alternatives --list` prior to running
   `centos2ol.sh` and reviewing the same output after switching. If you experience
   an issue with a package other than OpenJDK, please [open an issue][6]

## Limitations

1. The script currently needs to be able communicate with the CentOS and Oracle
   Linux yum repositories either directly or via a proxy.
1. The script currently does not support instances that are registered to a
   third-party management tool like Spacewalk, Foreman or Uyuni.
1. Compatibility with packages installed from third-party repositories is
   expected but not guaranteed. Some software doesn't like the existence of an
   `/etc/oracle-release` file, for example.
1. Packages that install third-party and/or closed-source kernel modules, e.g.
   commercial anti-virus products, may not work after switching.
1. The script only enables the base repositories required to enable switching
   to Oracle Linux. Users may need to enable additional repositories to obtain
   updates for packages already installed (see [issue #1][4].

## Debugging

Run `sudo bash -x centos2ol.sh` to switch your CentOS instance to Oracle Linux
in debug mode. This will print a trace of commands and their arguments or
associated word lists after they are expanded but before they are executed.

## Get involved

We welcome contributions! See our [contribution guidelines][5].

## Support

* Open a [GitHub issue][6] for non-security related bug reports, questions, or
  requests for enhancements.
* To report a security issue or vulnerability, please follow the
  [reporting security vulnerabilities][7] instructions.

## Resources

For more information on Oracle Linux, please visit [oracle.com/linux][8].

## License

Copyright (c) 2020, 2021 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at
<https://oss.oracle.com/licenses/upl/>

[1]: https://blogs.oracle.com/linux/cve-2020-10713-grub2-boothole
[2]: https://wiki.centos.org/AdditionalResources/Repositories/CentOSPlus
[3]: https://raw.githubusercontent.com/oracle/centos2ol/main/centos2ol.sh
[4]: https://github.com/oracle/centos2ol/issues/1
[5]: ./CONTRIBUTING.md
[6]: https://github.com/oracle/centos2ol/issues
[7]: ./SECURITY.md
[8]: https://www.oracle.com/linux
[9]: https://bugzilla.redhat.com/show_bug.cgi?id=1200302
