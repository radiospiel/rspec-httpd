# rspec-httpd

A gem to test HTTP servers with real requests.

## Usage

TODO

### Releasing a new gem version

TLDR: Do a `bundle exec rake release`.

- Releasing a gem version on the master branch:

    rake release

- Releasing a gem version on the stable branch:

    rake release:stable

These rake tasks automatically bump the version number. If you want to determine the target version yourself use

    VERION=1.2.3 rake release

or

    VERION=1.2.3 rake release:stable
