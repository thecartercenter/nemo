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

## Installation

For production scenarios, [Sassafras Tech Collective](http://sassafras.coop) offers managed production instances. Contact them for details. Or you can follow [this guide](docs/production-setup.md) to setup an instance on an Ubuntu server.

To setup a development environment, follow [this guide](docs/development-setup.md).

## How Do I Contribute to ELMO?

ELMO is 100% open-source. We would like you to be part of the ELMO community! We accept and encourage contributions from the public. You can start by filing a bug report or feature request using the 'Issues' feature on Github. Or contact [Tom Smyth](https://github.com/hooverlunch) for more info.

### ELMO Data Model

Contributors may find our auto-generated [Entity-Relationship Diagram (ERD)](docs/erd.pdf) useful.
You can generate it by running ```rake db:migrate ``` if adding new migrations or ```rake erd``` to run on its own. To skip running it when doing migrations run ```NO_DIAGRAM=1 rake db:migrate```

### Contributing

1. **Clone the Repo**

  ```
  git clone https://github.com/thecartercenter/elmo.git
  ```

2. **Create a New Branch**

  ```
  cd elmo
  git checkout -b my_new_branch
  ```

3. **Code**
  * Adhere to common conventions in the existing code
  * Include tests and make sure they pass

4. **Commit**
  - **NEVER leave the commit message blank!** Provide a detailed, clear, and complete description of your commit!
  - If you have several commits, please make sure that they are **squashed** into one commit with a good summarizing commit message before pushing.

5. **Update Your Branch**

  ```
  git checkout master
  git pull --rebase
  ```

6. **Fork**

  ```
  git remote add mine git@github.com:<username>/elmo.git
  ```

7. **Push to Your Remote**

  ```
  git push mine new_elmo_branch
  ```

8. **Issue a Pull Request**
  - Navigate to the ELMO repo you pushed to (e.g. https://github.com/username/elmo)
  - Click "Pull Request"
  - Write your branch name in the field (filled with "master" by default)
  - Click "Update Commit Range"
  - Verify the changes are included in the "Commits" tab
  - Verify that the "Files Changed" include all your changes
  - Enter details about your contribution with a meaningful title.
  - Click "Send pull request"

9. **Feedback**

  The ELMO team may request changes to your code. Learning and communication is part of the open source process!

## Acknowledgements

Parts of this document are based on the [Discourse Project](http://discourse.org) contribution guide at https://github.com/discourse/discourse/blob/master/CONTRIBUTING.md.
