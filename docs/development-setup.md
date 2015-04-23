# ELMO Development Setup

### Package Managers

Note to install the software below we recommend the following package managers:

- Mac OS X: Homebrew
- Linux/Unix: bundled package manager (e.g. apt-get, yum)

### Required Software

1. **Ruby 2.0+**

1. **Memcached 1.4+**
  - For development environments, caching is only needed if you are developing a feature that uses caching and want to test it. In this case, be sure to increase the default slab page size to 2 MB. This is done by passing `-I 2m` to the `memcached` command.

1. **MySQL 5.0+**
  - Create an empty database and accompanying user for use by the app (e.g. database *elmo_development* with username *elmo*)
  - Set up mysql for timezone support: See [doc here](http://dev.mysql.com/doc/refman/5.5/en/time-zone-support.html)

1. **Sphinx 2.0.6+**
  - Sphinx is an open source search engine.
  - It should be available through any of the package managers listed above. If not it can be built from source.
  - It is important that Sphinx be installed **with MySQL bindings**. This is not turned on by default in some cases.
  - The Rails Gem that talks to Sphinx is called Thinking Sphinx.
  - The [Thinking Sphinx site](http://pat.github.io/thinking-sphinx/) is a good place to go for troubleshooting and documentation.

1. **PhantomJS 1.9+**
  - PhantomJS is a headless browser that allows testing JavaScript.
  - It should be available through any of the package managers listed above. If not it can be built from source.
  - The Rails Gem that talks to PhantomJS is called Poltergeist.

1. **Firefox**
  - Firefox is used for automated browser testing.

1. **GraphViz 2.36+**
  - [GraphViz](http://graphviz.org/) is used to visualize the relationships between data in the database.

1. **Qt 4.8+**
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

1. **Run the tests**
  - Run `rspec`.
  - All tests should pass. Running them takes a few minutes.

1. **Build the Sphinx index**
  - Run `rake ts:rebuild`
  - This should also start the Sphinx daemon (searchd). If at any time it needs to be restarted, you can also run `rake ts:start`

1. **Start the server**
  - For a development setup, just run `rails s`.

1. **Login**
  - Navigate to http://localhost:3000
  - Login using username **admin** and password **temptemp** (make sure to change the password).
  - Create a new Mission and get started making forms!
