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
    sudo apt-get -y install nano git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev libmysqlclient-dev python-software-properties nodejs sphinxsearch memcached imagemagick

### Get ELMO source code and change into project directory

    git clone https://github.com/thecartercenter/elmo
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
    createdb elmo_production

### Configure ELMO

    cp config/database.yml.example config/database.yml

You shouldn't need to edit `database.yml` if you followed the PostgreSQL setup instructions above.

    cp config/initializers/local_config.rb.example config/initializers/local_config.rb
    nano config/initializers/local_config.rb

Enter sensible values for the settings in the file. Entering a functioning email server is important as ELMO relies on email to send broadcasts, and registration info, and password reset requests. Once you have ELMO running, you can test your email setup by creating a new user for yourself and delivering the login instructions via email or by using the password reset feature.

### Theming ELMO

If you want to change the colors for ELMO's themeable elements, perform the following steps:

    cp app/assets/stylesheets/all/variables/_default_theme.scss app/assets/stylesheets/all/variables/_theme.scss
    nano app/assets/stylesheets/all/variables/_theme.scss

Enter new color values for the components in the file.

In order to change the logo you must add the file to the folder `app/images/` (we recommend naming it `logo-override.png`) and modify the setting `configatron.logo_path` in `config/initializers/local_config.rb` to `"logo-override.png"` (or the actual name of the new logo file)

Once that's done, proceed with the final config.

### Final config

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
    # Build search indices
    bundle exec rake ts:rebuild
    # Start background job processor
    bundle exec bin/delayed_job start
    # Restart server
    sudo service nginx restart

### Generate admin user, login and enjoy!

Generate an admin user and note the password that is output to the console.

    bundle exec rake db:create_admin

Visit https://yourdomain.example.org in your browser (replace with your real domain name). The ELMO login screen should appear. Login with username **admin** and the password created in the previous step.

**IMPORTANT**: Change the admin user's password immediately by clicking on 'admin' in the top right.

See the [ELMO Documentation](http://getelmo.org/documentation/start/) for help on using your new ELMO instance!

### Upgrading

**IMPORTANT**: If you are upgrading from v5.x or earlier, see the instructions below on converting to PostgreSQL.

When new versions of ELMO are released, you will want to upgrade. To do so, ssh to your server and change to the `elmo` directory, then:

    git pull
    bundle install --without development test --deployment
    bundle exec whenever -i elmo
    bundle exec rake db:migrate
    bundle exec rake assets:precompile
    bundle exec rake ts:rebuild
    bundle exec bin/delayed_job restart
    touch tmp/restart.txt

Then load the site in your browser. You should see the new version number in the page footer.

### Converting an Existing Instance from MySQL to PostgreSQL

1. Install PostgreSQL (see above).
1. First upgrade to version v5.16.x, which is the last MySQL compatible version.
1. `cp config/mysql2postgres.yml.example config/mysql2postgres.yml`
1. In `config/mysql2postgres.yml`, ensure the database under `mysql_data_source` matches your MySQL database name.
1. Ensure a database `elmo_production` exists in PostgreSQL (note that anything in this DB will be destroyed).
1. Ensure you can connect to the database (e.g. using `psql elmo_production`) from the user account that runs the app. If you need a password or different host, be sure to update the mysql2postgres.yml file to reflect this.
1. It is best to turn off the server at this point to prevent any data corruption.
1. From the project root, run `RAILS_ENV=production bundle exec mysqltopostgres config/mysql2postgres.yml`.
1. Ignore the `no COPY in progress` message.
1. Update `config/database.yml` to point to Postgres. Use `config/database.yml.example` as a guide.
1. Upgrade to version v6+. Version 6+ is required when running against Postgres.
1. Restart your server. You should now be running on PostgreSQL!
1. Run bundle exec rake ts:rebuild to rebuild your indices against the new DB and restart Sphinx.
1. If you are using a regular DB backup dump command via cron, be sure to update it to use `pg_dump` instead of `mysqldump`.

Troubleshooting

* `MysqlPR::ClientError::ServerGoneError: The MySQL server has gone away` - Check your DB name in `config/mysql2postgres.yml`.


### Troubleshooting

If the above is not successful, contact info@getelmo.org or info@sassafras.coop for assistance.
