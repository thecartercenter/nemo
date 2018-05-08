# ELMO
ELMO is a mobile data collection and analysis web application. Originally designed for the [Carter Center](http://www.cartercenter.org) for election observation missions, ELMO can be used in many different contexts for data collection.

Consider ELMO if you need:

- Integrated form design
- Standardized form sets
- Multiple data entry paths, including web, ODK Collect, and SMS
- Multiple mission/project management
- Advanced user management with multiple permission levels
- SMS broadcasting
- Custom, real-time reporting
- Offline operation in poorly-connected areas

To learn more about the history and goals of the project, [visit the ELMO project site](http://getelmo.org).
You can also learn more about The Carter Center's Election Standards [here](http://cartercenter.org).

## Supported Releases

These release lines are currently receiving backports of all bug fixes.

| Number | Original Release Date | Major Features Since Previous Version |
|---|---|---|
| v7.x | 2017-11-22 | UUIDs, barcode question type |
| v8.x | 2018-01-25 | Multiple conditions, skip logic |

Each time a patch is backported to one of these releases, the new release will have its micro version number incremented. e.g. if v7.0.3 was the latest release in the 7.0 line, the new release will be given the number v7.0.4.

Generally, a new release line will be added to this list when some important new functionality is added to the system.

Release lines will be removed from this list when it is determined that:

1. a newer release line is adequately stable for production environments
2. any groups that may be using the release line are prepared to upgrade to the newer line and to perform any user training that may be necessary

## Production Setup

For production scenarios, [Sassafras Tech Collective](http://sassafras.coop) offers managed production instances. Contact them for details. Or you can follow the [production setup guide](docs/production-setup.md) to setup an instance on an Ubuntu server.

## Contributing

ELMO is 100% open-source. We would like you to be part of the ELMO community! We accept and encourage contributions from the public. You can start by filing a bug report or feature request using a [Github issue](https://github.com/thecartercenter/elmo/issues).

Pull requests are also welcome, but discussing things first in an issue is always a good idea.

See the [development environment setup guide](docs/development-setup.md) to get started with the code.

### ELMO Data Model

Contributors may find our auto-generated [Entity-Relationship Diagram (ERD)](docs/erd.pdf) useful.




## Acknowledgements

This project is happily tested with BrowserStack!
[![Tested with BrowserStack](https://www.browserstack.com/images/layout/browserstack-logo-600x315.png)](https://www.browserstack.com)
