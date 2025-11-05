# NEMO

[![Build and Deploy](https://github.com/Wbaker7702/nemo/actions/workflows/build-deploy.yml/badge.svg)](https://github.com/Wbaker7702/nemo/actions/workflows/build-deploy.yml)
[![Tests](https://github.com/Wbaker7702/nemo/actions/workflows/tests.yml/badge.svg)](https://github.com/Wbaker7702/nemo/actions/workflows/tests.yml)

NEMO is a mobile data collection and analysis web application. Originally designed for the [Carter Center](https://www.cartercenter.org), it can be used in many different contexts for data collection.

Consider NEMO if you need:

- Integrated form design
- Standardized form sets
- Multiple data entry paths, including web, ODK Collect, and SMS
- Multiple mission/project management
- Advanced user management with multiple permission levels
- SMS broadcasting
- Custom, real-time reporting
- Offline operation in poorly-connected areas

To learn more about the history and goals of the project, [visit the project site](https://getnemo.org).
You can also learn more about The Carter Center [here](https://cartercenter.org).

## Documentation

### Build and Deployment

NEMO uses GitHub Actions for continuous integration and deployment. The CI/CD pipeline automatically builds, tests, and deploys the application.

- **Build Status:** Automated builds run on every push
- **Deployment:** Automated deployment to staging (develop branch) and production (main branch)
- **CI/CD Guide:** See the [CI/CD Pipeline Documentation](docs/ci-cd-pipeline.md) for details

### Usage

See the [NEMO Documentation](https://getnemo.readthedocs.io) for help on using your new NEMO instance!

### Production Setup

You can follow the [production setup guide](docs/production-setup.md) to set up an instance on an Ubuntu server.
For production scenarios, [Sassafras Tech Collective](https://sassafras.coop) also offers managed production instances. Contact them for details.

### Contributing

NEMO is 100% open-source. We would like you to be part of the community! We accept and encourage contributions from the public.
You can start by filing a bug report or feature request using a [Github issue](https://github.com/thecartercenter/nemo/issues).
Pull requests are also welcome, but discussing things first in an issue is always a good idea.

See the [development environment setup guide](docs/development-setup.md) to get started with the code.
Contributors may also find our [architecture guide](docs/architecture.md) and auto-generated [Entity-Relationship Diagram (ERD)](docs/erd.pdf) useful.
