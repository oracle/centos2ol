# Switch from CentOS to Oracle Linux

This script is designed to automatically switch a CentOS instance to Oracle Linux
by removing any CentOS-specific packages or replacing them with the Oracle Linux
equivalent.

## Supported versions

This script currently supports switching CentOS Linux 6, CentOS Linux 7 and
CentOS Linux 8. It does not support CentOS Stream.

## Before you switch

1. Ensure your CentOS `yum` or `dnf` configuration is working, i.e. there are no
   stale repositories.
1. Disable all non-CentOS repositories. You can re-enable them after the switch.
1. Ensure you have at least 5GB of free space in `/var/cache`.
1. All automatic updates, e.g. via `yum-cron` should be disabled.

## Usage

1. Login to your CentOS Linux 6, 7 or 8 instance as a user who has `sudo` privileges.
1. Either clone this repository or download the [`centos2ol.sh`](./centos2ol.sh) script.
1. Run `sudo bash centos2ol.sh` to switch your CentOS instance to Oracle Linux.

## Limitations

1. The script currently needs to be able communicate with the CentOS and Oracle
   Linux yum repositories either directly or via a proxy.
1. The script currently does not support instances that are registered to a
   third-party management tool like Spacewalk, Foreman or Uyuni.
1. Compatibility with packages installed from third-party repositories is
   expected but not guaranteed. Some software doesn't like the existence of an
   `/etc/oracle-release` file, for example.
1. The script only enables the base repositories required to enable switching
   to Oracle Linux. Users may need to enable additional repositories to obtain
   updates for packages already installed (see [issue #1](https://github.com/oracle/centos2ol/issues/1)).

## Get involved

We welcome contributions! See our [contribution guidelines](./CONTRIBUTING.md).

## Support

* Open a [GitHub issue](https://github.com/oracle/centos2ol/issues) for non-security related bug reports, questions, or requests for enhancements.
* To report a security issue or vulnerability, please follow the [reporting security vulnerabilities](./SECURITY.md) instructions.

## Resources

For more information on Oracle Linux, please visit <https://www.oracle.com/linux>.

## License

Copyright (c) 2020 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
