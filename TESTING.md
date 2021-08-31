# Style and integration testing

Any new functionality added to `centos2.ol.sh` should include an update to the
test framework for that functionality.

## Prerequisites

The following tools must be installed before running any tests:

* Ruby 2.6
* [`shellcheck`](https://github.com/koalaman/shellcheck) available in `$PATH`
* [Oracle VM VirtualBox](https://www.virtualbox.org)
* [Vagrant](https://www.vagrantup.com)

The following command needs to be run once to ensure all the required RubyGems
are installed into the `vendor/bundle` directory:

```shell
bundle install
```

## Style tests

Run `shellcheck` and `rubocop` over the `centos2.ol` script
and the test framework files, including `Gemfile` and `Rakefile`:

```bash
bundle exec rake style
```

Just check the `centos2ol.sh` shell script using `shellcheck`:

```bash
bundle exec rake style:shell
```

Just check the Ruby test framework using `rubocop`:

```bash
bundle exec rake style:ruby
```

## Integration tests

Check that the `centos2ol.sh` script can successfully switch each major
version of CentOS to Oracle Linux and that each parameter works as expected.
This test uses Oracle VM VirtualBox, Vagrant and Kitchen and can take a long
time to complete. It requires virtualization support on the host on which it
runs.

```bash
bundle exec rake integration:vagrant:test
```

A successful run should finish with output similar to this:

```bash
Profile Summary: 1 successful control, 0 control failures, 0 controls skipped
Test Summary: 3 successful, 0 failures, 0 skipped
       Finished verifying <uek-centos-83> (0m1.97s).
       Finished testing <uek-centos-83> (6m3.67s).
-----> Destroying <uek-centos-83>...
       ==> default: Forcing shutdown of VM...
       ==> default: Destroying VM and associated drives...
       Vagrant instance <uek-centos-83> destroyed.
       Finished destroying <uek-centos-83> (0m4.61s).
-----> Test Kitchen is finished. (19m7.22s)
```
