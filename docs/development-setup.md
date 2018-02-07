# ELMO Development Setup

### Package Managers

Note to install the software below we recommend the following package managers:

- Mac OS X: Homebrew
- Linux/Unix: bundled package manager (e.g. apt-get, yum)

### Required Software

1. **Ruby 2.0+**

1. **Memcached 1.4+**
  - For development environments, caching is only needed if you are developing a feature that uses caching and want to test it. In this case, be sure to increase the default slab page size to 2 MB. This is done by passing `-I 2m` to the `memcached` command.

1. **PostgreSQL 9.4+**
  - Create an empty database for use by the app (typically *elmo_development*)

1. **ImageMagick 6.7+**
  - ImageMagick is used to resize uploaded images.
  - It should be available through any of the package managers listed above. If not it can be built from source.

1. **Chrome (Browser) 60+**
  - Used for automated browser testing.

1. **Chromedriver 2.35+**
  - Handles running Chrome headlessly for feature specs.
  - It should be available through any of the package managers listed above. If not it can be built from source.
  - The Rails Gem that talks to Chromedriver is called `selenium-webdriver`.

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

1. **Bundle, configure, and load schema**
  - Install the required gems by running `bundle install` in the project directory.
  - Copy `config/database.yml.example` to `config/database.yml` and edit `database.yml` to point to your database.
  - Copy `config/initializers/local_config.rb.example` to `config/initializers/local_config.rb` and adjust any settings. Note that the reCAPTCHA and Google Maps API Key must be valid keys for those services in order for tests to pass.
  - Setup the UUID postgres extension (must be done as postgres superuser): `sudo -u postgres psql elmo_development -c 'CREATE EXTENSION "uuid-ossp"'`
  - Load the database schema: `rake db:schema:load`.
  - Create an admin account: `rake db:create_admin`. You should receive a message like this: "Admin user created with username admin, password hTyWc9Q6" (The password is random, copy it to be used on your first login).

1. **Run the tests**
  - Run `rspec`.
  - All tests should pass. Running them takes about 10-15 minutes.
  - If you have trouble debugging a feature spec, you can run it headed (so you can watch the browser go through the spec) by doing `HEADED=1 bundle exec rspec spec/features/your_spec.rb`.

1. **Start the server**
  - For a development setup, just run `rails s`.

1. **Login**
  - Navigate to http://localhost:3000
  - Login with username **admin** and use the random password that was generated when you ran `rake db:create_admin` (make sure to change the password after login).
  - Create a new Mission and get started making forms!

### Testing with ODK

1. **Download the ODK application onto your Android phone or tablet**
  - https://opendatakit.org/

1. **Configure your rails development server so ODK can find it**
  - Run `rails s -p 8443 -b 0.0.0.0`

1. **Create a user and password**

1. **Publish your form in ELMO**

1. **Point the ODK app to your development server**
  - In ODK, go to `General Settings > Platform Settings > URL`
  - For the URL put: `http://YOURIP:8443/m/yourmission`
  - Also put in your username and password

1. **Retrieve Form**
  - In ODK, you should now be able to go to `Get Blank Form` to download the forms from ELMO
