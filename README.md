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

To learn more about the history and goals of the project, [visit the ELMO project site](http://getelmo.org).
You can also learn more about The Carter Center's Election Standards [here](http://cartercenter.org).

## How Do I Install ELMO?

In the future, we plan to offer managed instances of ELMO.

For an easy production setup, PaaS providers like [Heroku](http://heroku.com) or [Engine Yard](http://engineyard.com) would work well for ELMO.

Or to setup an instance manually for development or production use, you can follow the instructions below.

Note that manually setting up a Rails application for production use can be a complicated process, and the best practices for doing so change regularly. Your best bet is a web search for something like 'deploying rails app to ubuntu'.

### Package Managers

Note to install the software below we recommend the following package managers:

- Mac OS X: Homebrew
- Linux/Unix: bundled package manager (e.g. apt-get, yum)
- Windows: Npackd

### Required Software

1. **Ruby 1.9.3+**

1. **Memcached 1.4+**
  - Ensure memcached is running before starting server, even for development, since caching is enabled in development and production environments.
  - For production environments, ensure memcached is running on port 11219
  - For development environments, be sure to increase the default slab page size to 2 MB. This is done by passing `-I 2m` to the `memcached` command.

1. **MySQL 5.0+**
  - Create an empty database and accompanying user for use by the app (E.g. development database *elmo_d* with username *elmo*)
  - Set up mysql for timezone support: See [doc here](http://dev.mysql.com/doc/refman/5.5/en/time-zone-support.html)

1. **Web Server**
  - If your instance is for development only, you can use Rails' built-in web server by running `rails s`, as discussed below.
  - If your instance is for production use, you will need a production-grade web server, such as nginx or Apache, and app server, such as Passenger, Unicorn, Thin, etc.

1. **Sphinx 2.0.6+**
  - Sphinx is an open source search engine.
  - It should be available through any of the package managers listed above. If not it can be built from source.
  - It is important that Sphinx be installed **with MySQL bindings**. This is not turned on by default in some cases.
  - The Rails Gem that talks to Sphinx is called Thinking Sphinx.
  - The [Thinking Sphinx site](http://pat.github.io/thinking-sphinx/) is a good place to go for troubleshooting and documentation.

1. **PhantomJS 2.0+** (Development only)
  - PhantomJS is a headless browser that allows testing JavaScript.
  - It should be available through any of the package managers listed above. If not it can be built from source.
  - The Rails Gem that talks to PhantomJS is called Poltergeist.

1. **Firefox** (Development only)
  - Firefox is used for automated browser testing.

1. **GraphViz 2.36+** (Development only)
  - [GraphViz](http://graphviz.org/) is used to visualize the relationships between data in the database.

1. **Qt 4.8+** (Development only)
  - Qt is a cross-platform development kit that is needed by the `capybara-webkit` gem.
  - See [here](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit) for some installation instructions.

### Running the App

1. **Retrieve project files using Git**

  ```
  git clone https://github.com/thecartercenter/elmo.git
  cd elmo
  ```

  If developing, it's best to work off the development branch:

  ```
  git checkout develop
  ```

1. **Bundle, configure, and migrate**
  - Install the required gems by running `bundle install` in the project directory.
  - Copy `config/database.yml.example` to `config/database.yml` and edit `database.yml` to point to your database.
  - Copy `config/thinking_sphinx.yml.example` to `thinking_sphinx.yml` and adjust any settings (usually not necessary).
  - Copy `config/initializers/local_config.rb.example` to `config/initializers/local_config.rb` and adjust any settings.
  - Run database migrations: `rake db:migrate`. If the diagramming step hangs, run `NO_DIAGRAM=true rake db:migrate`.
  - Create an admin account: `rake db:create_admin`.

1. **Build the Sphinx index**
  - Run `rake ts:rebuild`
  - This should also start the Sphinx daemon (searchd). If at any time it needs to be restarted, you can also run `rake ts:start`

1. **Run Whenever to setup cron jobs**
  - Run `whenever -i elmo`
  - Run `crontab -l` and verify that jobs have been added.

1. **Start the server**
  - For a development setup, just run `rails s`.
  - For a production setup, this will depend on your choice of servers, process monitors, etc., and goes beyond the scope of this document.

1. **Login**
  - Navigate to the app's URL (http://localhost:3000 by default in a development setup).
  - Login using username **admin** and password **temptemp** (make sure to change the password).
  - Create a new Mission and get started making forms!

### Running the tests

ELMO currently uses a mixture of legacy Test::Unit tests and RSpec specs. Both should be run. Use `rake test && rspec`.

## How Do I Contribute to ELMO?

ELMO is 100% open-source. We would like you to be part of the ELMO community! We accept and encourage contributions from the public. You can start by filing an bug report or feature request using the 'Issues' feature on Github. Or contact [Tom Smyth](https://github.com/hooverlunch) for more info.

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
