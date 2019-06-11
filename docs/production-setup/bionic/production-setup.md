# Basic ELMO Production Setup Guide

This guide assumes:

* You have an Ubuntu server up and running (version 18.04 recommended).
* You have a domain name (e.g. yoursite.example.com) pointing to the server's IP address.
* Port 443 on the server is open to the world.
* You have ssh'ed to the server as the root user or a user with sudo privileges (`root` is assumed as the username below).

### Create `deploy` User

This will be the (unprivileged) user under which the app runs.

    sudo adduser deploy # Enter a password and leave the rest blank.

### Install dependencies

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y nano git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev memcached imagemagick vim-gtk ntp
    sudo systemctl enable ntp

Remove the default ruby installation so we can install our own later:

    sudo apt remove ruby

### Install Nginx and Passenger

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main > /etc/apt/sources.list.d/passenger.list'
    sudo apt update && sudo apt install -y nginx apt-transport-https ca-certificates libnginx-mod-http-passenger

### Install PostgreSQL and create database

    sudo apt install -y postgresql postgresql-contrib postgresql-server-dev-10
    sudo -u postgres createuser -d deploy
    sudo -u postgres createdb elmo_production -O deploy
    sudo -u postgres psql elmo_production -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
    sudo -u postgres psql elmo_production -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto"'

### Setup SSL and configure Nginx

#### To get a free SSL certificate from LetsEncrypt

    sudo rm -f /etc/nginx/nginx.conf && sudo nano /etc/nginx/nginx.conf

Paste the contents of [this config file](nginx-certbot.conf). Update the `server_name` setting to match your domain.

Then follow the [short instructions at the Certbot site](https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx).
The Certbot program should obtain your certificate, add the necessary settings to your nginx configuration file, and restart the server.

Certificate auto-renewal is required since LetsEncrypt certificates are only valid for 90 days.
To auto-renew your certificate, add the following to your crontab (type `crontab -e`):

    X * * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin && sudo /usr/bin/certbot renew --no-self-upgrade > ${HOME}/certbot-cron.log 2>&1

replacing `X` with a minute a few minutes into the future (e.g. if it's 12:19:23 now, enter 20 or 21). Wait for that time to pass, then:

    cat ~/certbot-cron.log

and ensure the command ran smoothly. It should say that no certificates are due for renewal.

#### To use an existing SSL certificate

Obtain or locate your SSL certificate's `.crt` and `.key` files.

    sudo mkdir /etc/nginx/ssl
    sudo chmod 400 /etc/nginx/ssl
    sudo nano /etc/nginx/ssl/ssl.crt

Paste the contents of your `.crt` file, save, and exit.

    sudo nano /etc/nginx/ssl/ssl.key

Paste the contents of your `.key` file, save, and exit. Be careful not to share the contents of your `.key` file with anyone. Then:

    sudo rm /etc/nginx/nginx.conf && sudo nano /etc/nginx/nginx.conf

Paste the contents of [this config file](nginx-self-ssl.conf). Update the `server_name` setting to match your domain.

### Test your nginx and SSL config

Try visiting `http://yoursite.example.com` in your browser. You should be redirected to the HTTPS version of the URL,
the secure/lock icon should appear in your browser, and you should get a "404 Not Found" message. If any of the above is not true, you
will need to troubleshoot. Otherwise, you can continue.

### Switch to the `deploy` user

The commands in the next few sections will be run as the `deploy` user.
All app-specific commands like `bundle`, `yarn`, and `rake` should always be run as the `deploy` user.
To switch to the `deploy` user, do:

    sudo su - deploy

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

### Install nvm, Node.js, and Yarn

    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    exec $SHELL
    nvm install
    npm install -g yarn

### Configure the App

    cp config/database.yml.example config/database.yml

You shouldn't need to edit `database.yml` if you followed the PostgreSQL setup instructions above.

    cp config/initializers/local_config.rb.example config/initializers/local_config.rb
    nano config/initializers/local_config.rb

Read the comments in the file and enter sensible values for the settings. Then:

    cp config/settings.local.yml.example config/settings.local.yml
    nano config/settings.local.yml

Similarly, read the comments in the file and enter sensible values for the settings.

Entering a functioning email server is important as ELMO relies on email to send broadcasts, and registration info, and password reset requests. Once you have ELMO running, you can test your email setup by creating a new user for yourself and delivering the login instructions via email or by using the password reset feature.

### Prepare the App

    # Set Rails environment.
    echo 'export RAILS_ENV=production' >> ~/.bashrc
    exec $SHELL
    nvm use

    # Install gems and yarn packages.
    bundle install --without development test --deployment
    yarn install --production

    # Setup cron jobs
    bundle exec whenever -i elmo

    # Load database schema
    bundle exec rake db:schema:load

    # Precompile assets
    bundle exec rake assets:precompile

    # Generate admin user (note the password that is output)
    bundle exec rake db:create_admin

### Test Email

Email is important for NEMO to work properly. To test it, run:

    bundle exec rails console

and then enter the following, replacing EMAIL with an email address you can check and that is _different from_ the one you entered for the site's email.

    class T < ApplicationMailer; def t; mail(to: "EMAIL", subject: "Test 1", body: "Test 1"); end; end; T.t.deliver_now

The console should print a line starting with `=> #<Mail::Message:` and the email should arrive.
If you get an error, you will need to check your mail settings. It's also possible the email will end
up in your spam folder because of its short body and subject.
If this happens, try doing a NEMO password reset (click the link on the login screen).
If this email also ends up in your spam folder, you should raise the issue with your email provider.

### Create a Delayed Job service

Delayed Job handles background tasks. It is best to create a `systemd` service wrapper for it so that it will start
when the system is rebooted. (Nginx/Passenger handle starting the main web service).

To do so:

    exit # Return to root/privileged user
    sudo nano /etc/systemd/system/delayed-job.service

Now paste the contents of [this configuration file](delayed-job.service) and save. Then:

    sudo systemctl daemon-reload
    sudo systemctl enable delayed-job
    sudo systemctl start delayed-job

If you then run:

    sudo systemctl status delayed-job

you should see the text "Active: active (running)" in the output. If something went wrong, there will be some
log output that will help you determine the issue.

### Enable log rotation

This will prevent your log files from becoming too large.

    sudo nano /etc/logrotate.conf

Add the following lines at the bottom of that file:

    /home/deploy/elmo/current/log/*.log {
      daily
      missingok
      rotate 7
      compress
      delaycompress
      notifempty
      copytruncate
    }

### Upgrade and clean up

The following command will upgrade and clean up your installed packages. Sometimes `autoremove` is helpful if you run low on disk space.

    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

### Check out the site!

You should now be able to visit https://yourdomain.example.org in your browser (replace with your real domain name).
The ELMO login screen should appear. Login with username **admin** and the password created above.

See the [ELMO Documentation](https://elmo-nemo.readthedocs.io) for help on using your new ELMO instance!

### Custom Theme

You can define a custom theme for the application. In the project root, run:

    bundle exec rake theme:init

This will create the files `/theme/style.scss`, `/theme/logo-light.png`, and `/theme/logo-dark.png`.
Update those files to reflect the desired theme. Ensure your new logos are the same size as the examples.

You will need to run `nvm use && bundle exec rake assets:precompile` (and re-start your server if it's currently running) for the theme to take effect.
The compiler will tell you if there are any errors in your `style.scss` file.

### Capistrano

If you want to use Capistrano to manage this instance, follow the [migration guide](https://redmine.sassafras.coop/projects/nemo/wiki/Migrating_a_manual_server_to_Capistrano).
This is mainly for Sassafras-managed instances.

### Upgrading

Upgrading should be done in stages. Start with the stage closest to your current version.

<details>
<summary>View older versions</summary>

#### Upgrading to v5.16.2

1. Follow the 'General Upgrade Instructions' below to upgrade to **v5.16.2**.
2. If you encounter a 'mismatched superclass' error when migrating, try running the migrate command again.

#### Upgrading to v6.11

1. Install PostgreSQL (see above).
1. As `deploy` user, in elmo directory on server, `cp config/mysql2postgres.yml.example config/mysql2postgres.yml`
1. In `config/mysql2postgres.yml`, ensure the database under `mysql_data_source` matches your MySQL database name.
1. Ensure a database `elmo_production` exists in PostgreSQL (note that anything in this DB will be destroyed).
1. Ensure you can connect to the database (e.g. using `psql elmo_production`) from the user account that runs the app. If you need a password or different host, be sure to update the mysql2postgres.yml file to reflect this.
1. It is best to stop nginx at this point to prevent any data corruption.
1. Run `bundle exec mysqltopostgres config/mysql2postgres.yml`.
    1. If you get the error `MysqlPR::ClientError::ServerGoneError: The MySQL server has gone away`, check your DB name, username, and password in `config/mysql2postgres.yml`.
1. Ignore the `no COPY in progress` message.
1. Update `config/database.yml` to point to Postgres. Use [this file](https://raw.githubusercontent.com/thecartercenter/elmo/v6.11/config/database.yml.example) as a guide. The `test` and `development` blocks are not needed.
1. If you are using a regular DB backup dump command via cron, be sure to update it to use `pg_dump` instead of `mysqldump`.
1. You should now follow the 'General Upgrade Instructions' below to upgrade to **v6.11**.

#### Upgrading to v7.2

1. Install Ruby 2.4.3 and Bundler:

        cd "$(rbenv root)"/plugins/ruby-build
        git pull
        cd -
        rbenv install 2.4.3
        rbenv global 2.4.3
        gem install bundler
2. As root/privileged user: `sudo -u postgres psql elmo_production -c 'CREATE EXTENSION "uuid-ossp"'`
3. Follow the 'General Upgrade Instructions' below to upgrade to **v7.2**. Your data will be migrated to use UUIDs, and this may take awhile. Then you'll be all up to date!

#### Upgrading to v8.12

1. As the `deploy` user, install nvm, the appropriate node version, and yarn:

        curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
        exec $SHELL
        nvm install 8.9.4
        npm install -g yarn
3. Follow the 'General Upgrade Instructions' below to upgrade to **v8.12**.

</details>

#### Upgrading to v9.0

1. The data migrations in this upgrade may take some time if you have a lot of data. To protect your data, stop your server and DelayedJob, as privileged user: `sudo systemctl stop nginx && sudo systemctl stop delayed-job`
2. Follow the 'General Upgrade Instructions' below to upgrade to **v9.0**.
3. Start your server and DelayedJob: `sudo systemctl start nginx && sudo systemctl start delayed-job`

#### Upgrading to v9.1

1. Follow the 'General Upgrade Instructions' below to upgrade to **v9.1**.
2. Run `bundle exec rake option_set_reclone` to repair option set references that may exist in your database due to a bug in a previous version.

#### Upgrading to v9.2

1. Follow the 'General Upgrade Instructions' below to upgrade to **v9.2**.
2. Follow the instructions above under 'Configure the App' to setup your settings.local.yml file.

#### Upgrading to v9.6

1. As `deploy` user in project directory, run `gem update bundler --no-document` to update to Bundler 2.x.

#### Upgrading to v9.13

1. As the root user, run `sudo -u postgres psql elmo_production -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto"'` to enable a new extension.

#### Upgrading to latest master

1. Follow the 'General Upgrade Instructions' below.

#### General Upgrade Instructions

ssh to your server as the same root/privileged user used above. Then:

    sudo systemctl stop delayed-job && sudo systemctl stop nginx
    sudo su - deploy
    cd elmo
    nvm use # v8.12 or higher only

Make a backup of your database:

    mkdir -p tmp
    pg_dump elmo_production > tmp/`cat VERSION`-dump.sql
    ls -l tmp

Ensure that the dump file you created has non-zero size by looking in the directory listing.

Now, pull the latest code:

    git pull

If you want to upgrade to a particular version of ELMO, then try:

    git checkout vX.Y

where `X.Y` (or `X.Y.Z`) is the version number you want. Otherwise you should ensure you're on the master branch:

    git checkout master

If you get an error that `Your local changes to the following files would be overwritten by checkout`, you can usually
fix it by doing `git reset --hard`. This will wipe out any local changes to the code, which shouldn't be a problem
unless you changed it on purpose for some reason.

Then:

    bundle install --without development test --deployment
    bundle exec whenever -i elmo
    bundle exec rake assets:precompile
    bundle exec rake db:migrate

Now be sure to check the [commit history of the local config file](https://github.com/thecartercenter/elmo/commits/develop/config/initializers/local_config.rb.example) and/or run:

    diff config/initializers/local_config.rb.example config/initializers/local_config.rb

to see if anything needs to be updated in your local configuration.

Finally:

    exit # Back to privileged/root user
    sudo systemctl restart delayed-job && sudo systemctl restart nginx

Then load the site in your browser. You should see the new version number in the page footer.

### Troubleshooting

If the above is not successful, contact info@getelmo.org for assistance.
