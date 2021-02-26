# Contributing

We welcome your contributions! There are multiple ways to contribute.

## Issues

For bugs or enhancement requests, please [file a GitHub issue](https://github.com/oracle/centos2ol/issues)
unless it's security related. When filing a bug remember that the better written the bug is, the more likely
it is to be fixed.

If you think you've found a security vulnerability, do not open a GitHub issue.
Instead, please follow the instructions provided for [reporting security vulnerabilities](./SECURITY.md).

## Contributing Code

We welcome your code contributions. Before you submit a fix or enhancement, please
open an issue first so that we can discuss the nature of the contribution first.

You will also need to sign the [Oracle Contributor Agreement](https://www.oracle.com/technetwork/community/oca-486395.html) (OCA)
before we can accept any code contribution.

For pull requests to be accepted, the bottom of your commit message must have
the following line using the name and e-mail address you used for the OCA.

```text
Signed-off-by: Your Name <you@example.org>
```

This can be automatically added to pull requests by committing with:

```text
git commit --signoff
```

Only pull requests from committers that can be verified as having
signed the OCA can be accepted.

### Pull request process

1. Fork this repository
1. Create a branch in your fork to implement the changes. We recommend using
   the issue number as part of your branch name, e.g. `1234-fixes`
1. Ensure that any documentation is updated with the changes that are required
   by your fix.
1. Ensure that any samples are updated if the base image has been changed.
1. Ensure that you add or update any tests to ensure your new functionality is
   added to the test framework.
1. Submit the pull request. *Do not leave the pull request blank*. Explain exactly
   what your changes are meant to do and provide simple steps on how to validate
   your changes. Ensure that you reference the issue you created as well.
1. We will assign the pull request to 2-3 people for review before it is merged.

## Code of Conduct

Follow the [Golden Rule](https://en.wikipedia.org/wiki/Golden_Rule). If you'd like more specific
guidelines see the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/1/4/code-of-conduct/)
