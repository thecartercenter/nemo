# Basic ELMO Production Setup Guide

This guide assumes:

* You have an Ubuntu server up and running (version 16.04 recommended).
* You have a domain name (e.g. yoursite.example.com) pointing to the server's IP address.
* Port 443 on the server is open to the world.
* You have a valid SSL certificate for your domain. ELMO requires SSL for general security and to comply with ODK Collect's requirement for same. Free SSL certificates are widely available nowadays. Try [here](https://google.com/search?q=free+ssl+certificate).
* You have ssh'ed to the server as a user with sudo privileges (`ubuntu` is assumed as the username).

For security reasons, it is not recommended to install ELMO as the `root` user.

### Install dependencies

    sudo apt-get update && sudo apt-get -y upgrade
    sudo apt-get -y install nano git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev libmysqlclient-dev python-software-properties nodejs memcached imagemagick

### Get ELMO source code and change into project directory

    git clone -b master https://github.com/thecartercenter/elmo
    cd elmo

### Install rbenv, Ruby, and Bundler

    git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    exec $SHELL
    # This step will take a few minutes.
    rbenv install `cat .ruby-version`
    echo "gem: --no-ri --no-rdoc" > ~/.gemrc
    gem install bundler
    exec $SHELL

### Install Nginx and Passenger

    gpg --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
    gpg --armor --export 561F9B9CAC40B2F7 | sudo apt-key add -
    # Add HTTPS support to APT
    sudo apt-get -y install apt-transport-https
    # Add the passenger repository
    sudo sh -c "echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main' >> /etc/apt/sources.list.d/passenger.list"
    sudo chown root: /etc/apt/sources.list.d/passenger.list
    sudo chmod 600 /etc/apt/sources.list.d/passenger.list
    sudo apt-get update
    # Install nginx and passenger
    sudo apt-get -y install nginx-full passenger

### Upload SSL certificate

Obtain or locate your SSL certificate's `.crt` and `.key` files.

    sudo mkdir /etc/nginx/ssl
    sudo chmod 400 /etc/nginx/ssl
    sudo nano /etc/nginx/ssl/ssl.crt

Paste the contents of your `.crt` file, save, and exit.

    sudo nano /etc/nginx/ssl/ssl.key

Paste the contents of your `.key` file, save, and exit. Be careful not to share the contents of your `.key` file with anyone.

### Configure Nginx

    sudo rm /etc/nginx/nginx.conf && sudo nano /etc/nginx/nginx.conf

Paste the contents of [this config file](nginx.conf). Update the `server_name` setting to match your domain. If your username is not `ubuntu`, also update the `root` and `passenger_ruby` settings to match your username. Save and exit.

### Install PostgreSQL and create database

    sudo /bin/su -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list"
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install postgresql-client-9.4 postgresql-9.4 postgresql-contrib-9.4 libpq-dev postgresql-server-dev-9.4
    sudo -u postgres createuser -d ubuntu
    createdb elmo_production -E UTF8 -l en_US.UTF-8
    sudo -u postgres psql elmo_production -c 'CREATE EXTENSION "uuid-ossp"'

### Configure ELMO

    cp config/database.yml.example config/database.yml

You shouldn't need to edit `database.yml` if you followed the PostgreSQL setup instructions above.

    cp config/initializers/local_config.rb.example config/initializers/local_config.rb
    nano config/initializers/local_config.rb

Enter sensible values for the settings in the file. Entering a functioning email server is important as ELMO relies on email to send broadcasts, and registration info, and password reset requests. Once you have ELMO running, you can test your email setup by creating a new user for yourself and delivering the login instructions via email or by using the password reset feature.

### Final Config

    # Set Rails environment.
    echo 'export RAILS_ENV=production' >> ~/.bashrc
    exec $SHELL
    # Install gems
    bundle install --without development test --deployment
    # Setup cron jobs
    bundle exec whenever -i elmo
    # Load database schema
    bundle exec rake db:schema:load
    # Precompile assets
    bundle exec rake assets:precompile
    # Start background job processor
    bundle exec bin/delayed_job start
    # Restart server
    sudo service nginx restart

### Custom Theme

You can define a custom theme for the application. In the project root, run:

```
rake theme:init
```

This will create the files `/theme/style.scss`, `/theme/logo-light.png`, and `/theme/logo-dark.png`. Update those files to reflect the desired theme. Ensure your new logos are the same size as the examples.

You will need to run `rake assets:precompile` (and re-start your server if it's currently running) for the theme to take effect. The compiler will tell you if there are any errors in your `style.scss` file.

### Generate admin user, login and enjoy!

Generate an admin user and note the password that is output to the console.

    bundle exec rake db:create_admin

Visit https://yourdomain.example.org in your browser (replace with your real domain name). The ELMO login screen should appear. Login with username **admin** and the password created in the previous step.

**IMPORTANT**: Change the admin user's password immediately by clicking on 'admin' in the top right.

See the [ELMO Documentation](http://getelmo.org/documentation/start/) for help on using your new ELMO instance!

### Upgrading

#### Upgrading from v5.x to v5.16

You should upgrade to v5.16 before moving on to v6.11. Follow the 'General Upgrade Instructions' below to upgrade to **v5.16** before moving to v6.x.

#### Upgrading from v5.16 to v6.11

You should upgrade to v6.11 before moving on to the latest master. Follow the instructions below to do so:

1. Install PostgreSQL (see above).
1. In project directory on server, `cp config/mysql2postgres.yml.example config/mysql2postgres.yml`
1. In `config/mysql2postgres.yml`, ensure the database under `mysql_data_source` matches your MySQL database name.
1. Ensure a database `elmo_production` exists in PostgreSQL (note that anything in this DB will be destroyed).
1. Ensure you can connect to the database (e.g. using `psql elmo_production`) from the user account that runs the app. If you need a password or different host, be sure to update the mysql2postgres.yml file to reflect this.
1. It is best to stop nginx at this point to prevent any data corruption.
1. From the project root, run `RAILS_ENV=production bundle exec mysqltopostgres config/mysql2postgres.yml`.
    1. If you get the error `MysqlPR::ClientError::ServerGoneError: The MySQL server has gone away`, check your DB name, username, and password in `config/mysql2postgres.yml`.
1. Ignore the `no COPY in progress` message.
1. Update `config/database.yml` to point to Postgres. Use [this file](https://raw.githubusercontent.com/thecartercenter/elmo/v6.11/config/database.yml.example) as a guide. The `test` and `development` blocks are not needed.
1. If you are using a regular DB backup dump command via cron, be sure to update it to use `pg_dump` instead of `mysqldump`.
1. You should now follow the 'General Upgrade Instructions' below to upgrade to **v6.11** before moving to the latest master.

#### Upgrading from v6.x to the latest master

1. Make a backup of your database: `pg_dump elmo_production > v6-dump.sql`
2. `sudo -u postgres psql elmo_production -c 'CREATE EXTENSION "uuid-ossp"'`
3. Follow the 'General Upgrade Instructions' below to upgrade to the latest master. Your data will be migrated to use UUIDs, and this may take awhile. Then you'll be all up to date!

#### General Upgrade Instructions

ssh to your server and change to the `elmo` directory, then:

    git pull

If you want to upgrade to a particular version of ELMO, then try:

    git checkout release-x.y

where `x.y` is the version number you want. Otherwise you should ensure you're on the master branch:

    git checkout master

Then:

    bundle install --without development test --deployment
    bundle exec whenever -i elmo
    bundle exec rake assets:precompile
    bundle exec rake db:migrate

Now be sure to check the [commit history of the local config file](https://github.com/thecartercenter/elmo/commits/develop/config/initializers/local_config.rb.example) and/or run:

    diff config/initializers/local_config.rb config/initializers/local_config.rb.example

to see if anything needs to be updated in your local configuration.

Finally:

    bundle exec bin/delayed_job restart
    touch tmp/restart.txt

Start nginx if it had been stopped. Then load the site in your browser. You should see the new version number in the page footer.

### Troubleshooting

If the above is not successful, contact info@getelmo.org or info@sassafras.coop for assistance.
