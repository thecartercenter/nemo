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

- Mac OS X: MacPorts or Homebrew
- Linux/Unix: bundled package manager (e.g. apt-get, yum)
- Windows: Npackd

### Required Software

1. **Ruby 1.9.3+**

1. **Memcached**
	- A good resource on how to install on a Mac is [here](http://www.jroller.com/JamesGoodwill/entry/installing_and_configuring_memcached)
	- Ensure memcached is running, even for development, since caching is enabled in development and production environments.

1. **MySQL 5.0+**
	- Create an empty database and accompanying user for use by the app (E.g. development database *elmo_d* with username *elmo*)

1. **Web Server**
	- If your instance is for development only, you can use Rails' built-in web server by running `rails s`, as discussed below.
	- If your instance is for production use, you will need a production-grade web server, such as nginx or Apache, and app server, such as Passenger, Unicorn, Thin, etc.

### Running the App

1. **Retrieve project files using Git**
	
  ```
  git clone https://github.com/thecartercenter/elmo.git
  ```

1. **Bundle, configure, and migrate**
	- Install the required gems by running `bundle install` in the project directory.
	- Copy `config/database.yml.example` to `config/database.yml` and edit `database.yml` to point to your database.
	- Copy `config/initializers/local_config.rb.example` to `config/initializers/local_config.rb` and adjust any settings.
	- Run database migrations: `rake db:migrate`.
	- Create an admin account: `rake db:create_admin`.
	
1. **Start the server**
	- For a development setup, just run `rails s`.
	- For a production setup, this will depend on your choice of servers, process monitors, etc., and goes beyond the scope of this document.

1. **Login**
	- Navigate to the app's URL (http://localhost:3000 by default in a development setup).
	- Login using username **admin** and password **temptemp** (make sure to change the password).
	- Create a new Mission and get started making forms!


## How Do I Contribute to ELMO?

ELMO is 100% open-source. We would like you to be part of the ELMO community! We accept and encourage contributions from the public.

### Reporting Bugs and Requesting Features

Please use our Redmine instance at http://redmine.sassafras.coop/projects/elmo. Bugs/feature requests can be reported anonymously.

### ELMO Data Model

Contributors may find our auto-generated [Entity-Relationship Diagram (ERD)](docs/erd.pdf) useful.

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
