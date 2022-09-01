# Basic NEMO Production Setup Guide

This guide assumes:

* You have an Ubuntu server up and running (version 20.04 recommended; see revision history for earlier versions).
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

### Configure a default text editor

    export EDITOR=vim # Option 1.
    export EDITOR=nano # Option 2.
    echo "export EDITOR=$EDITOR" | sudo tee -a ~/.bashrc /home/deploy/.bashrc

### Install Nginx and Passenger

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger focal main > /etc/apt/sources.list.d/passenger.list'
    sudo apt update && sudo apt install -y nginx apt-transport-https ca-certificates libnginx-mod-http-passenger

### Configure memcached

    sudo rm -f /etc/memcached.conf && sudo $EDITOR /etc/memcached.conf

Paste the contents of [this config file](memcached.conf), then restart: `sudo systemctl restart memcached`.

### Install PostgreSQL and create database

    sudo apt install -y postgresql postgresql-contrib postgresql-server-dev-12
    sudo -u postgres createuser -d deploy
    sudo -u postgres createdb nemo_production -O deploy
    sudo -u postgres psql nemo_production -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
    sudo -u postgres psql nemo_production -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto"'

Optional: Disable unattended upgrades to prevent Delayed Job from getting killed
(security note: make sure you upgrade regularly if you're going to disable this):

    sudo $EDITOR /etc/apt/apt.conf.d/50unattended-upgrades
    # Find the section called "Unattended-Upgrade::Package-Blacklist"
    # and add the following line:
        "postgresql-.*";

### Connect to a remote database (optional, advanced)

If you have split servers (e.g. web on one server and database on another), make sure to also modify the following:

Web server:
- Follow the instructions in the web server's `database.yml` to configure the connection

Database server:
- Modify `/etc/postgresql/12/main/pg_hba.conf` to allow remote connections
- Modify `/etc/postgresql/12/main/postgresql.conf` to listen on any ports needed

### Setup SSL and configure Nginx

#### To get a free SSL certificate from LetsEncrypt

    sudo rm -f /etc/nginx/nginx.conf && sudo $EDITOR /etc/nginx/nginx.conf

Paste the contents of [this config file](nginx-certbot.conf). Update the `server_name` setting to match your domain.

Then follow the [short instructions at the Certbot site](https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal).
The Certbot program should obtain your certificate, add the necessary settings to your nginx configuration file, and restart the server.

Certificate auto-renewal happens automatically with certbot as of ~2022.

#### To use an existing SSL certificate

Obtain or locate your SSL certificate's `.crt` and `.key` files.

    sudo mkdir /etc/nginx/ssl
    sudo chmod 400 /etc/nginx/ssl
    sudo $EDITOR /etc/nginx/ssl/ssl.crt

Paste the contents of your `.crt` file, save, and exit.

    sudo $EDITOR /etc/nginx/ssl/ssl.key

Paste the contents of your `.key` file, save, and exit. Be careful not to share the contents of your `.key` file with anyone. Then:

    sudo rm /etc/nginx/nginx.conf && sudo $EDITOR /etc/nginx/nginx.conf

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

### Get NEMO source code and change into project directory

    git clone https://github.com/thecartercenter/nemo nemo
    cd nemo

### Install rbenv, Ruby, and Bundler

    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc

    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    exec $SHELL

    # This step will take a few minutes.
    RUBY_CONFIGURE_OPTS=--disable-install-doc rbenv install `cat .ruby-version`
    echo "gem: --no-ri --no-rdoc" > ~/.gemrc
    gem install bundler
    exec $SHELL

### Install nvm, Node.js, and Yarn

    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
    exec $SHELL
    nvm install
    npm install -g yarn

Make sure to follow the instructions printed out by nvm related to putting the `NVM_DIR` lines in `.bashrc`.

### Configure the App

    cp config/database.yml.example config/database.yml

You shouldn't need to edit `database.yml` if you followed the PostgreSQL setup instructions above.

    cp .env .env.production.local
    $EDITOR .env.production.local

Read the comments in the file and enter sensible values for the settings.

Entering a functioning email server is important as NEMO relies on email to send broadcasts, and registration info, and password reset requests. Once you have NEMO running, you can test your email setup by creating a new user for yourself and delivering the login instructions via email or by using the password reset feature.

### Prepare the App

    # Set Rails environment.
    echo 'export RAILS_ENV=production' >> ~/.bashrc
    exec $SHELL
    nvm use

    # Install gems and yarn packages.
    bundle install --without development test --deployment
    yarn install --production

    # Setup cron jobs
    bundle exec whenever -i nemo

    # Load database schema and seed data
    bundle exec rake db:schema:load
    bundle exec rake db:seed

    # Precompile assets
    bundle exec rake assets:precompile

    # Generate admin user (note the password that is output)
    bundle exec rake db:create_admin

### Test Email

Email is important for NEMO to work properly. To test it, run:

    bundle exec rails console -e production

and then enter the following, replacing EMAIL with an email address you can check and that is _different from_ the one you entered for the site's email.

    class T < ApplicationMailer; def t; mail(to: "EMAIL", subject: "Test 1", body: "Test 1"); end; end; T.t.deliver_now

The console should print a line starting with `=> #<Mail::Message:` and the email should arrive.
If you get an error, you will need to check your mail settings. It's also possible the email will end
up in your spam folder because of its short body and subject.
If this happens, try doing a NEMO password reset (click the link on the login screen).
If this email also ends up in your spam folder, you should raise the issue with your email provider.

### Create a Delayed Job service

Delayed Job handles background tasks, such as data exports, SMS broadcasts, response deduplication,
and DB performance-related operations.

It is best to create a `systemd` service wrapper for it so that it will start
when the system is rebooted. (Nginx/Passenger handle starting the main web service).

To do so:

    exit # Return to root/privileged user
    sudo $EDITOR /etc/systemd/system/delayed-job.service

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

    sudo $EDITOR /etc/logrotate.conf

Add the following lines at the bottom of that file:

    /home/deploy/nemo/log/*.log {
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
The NEMO login screen should appear. Login with username **admin** and the password created above.

See the [NEMO Documentation](https://getnemo.readthedocs.io) for help on using your new NEMO instance!

### Custom Theme

You can define a custom theme for the application. In the project root, run:

    bundle exec rake theme:init

This will create the files `/theme/style.scss`, `/theme/logo-light.png`, and `/theme/logo-dark.png`.
Update those files to reflect the desired theme. Ensure your new logos are the same size as the examples.

Set the `NEMO_CUSTOM_THEME_SITE_NAME` environment variable in the `.env.production.local` file to customize the site name.

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
1. As `deploy` user, in `nemo` directory on server, `cp config/mysql2postgres.yml.example config/mysql2postgres.yml`
1. In `config/mysql2postgres.yml`, ensure the database under `mysql_data_source` matches your MySQL database name.
1. Ensure a database `nemo_production` exists in PostgreSQL (note that anything in this DB will be destroyed).
1. Ensure you can connect to the database (e.g. using `psql nemo_production`) from the user account that runs the app. If you need a password or different host, be sure to update the mysql2postgres.yml file to reflect this.
1. It is best to stop nginx at this point to prevent any data corruption.
1. Run `bundle exec mysqltopostgres config/mysql2postgres.yml`.
    1. If you get the error `MysqlPR::ClientError::ServerGoneError: The MySQL server has gone away`, check your DB name, username, and password in `config/mysql2postgres.yml`.
1. Ignore the `no COPY in progress` message.
1. Update `config/database.yml` to point to Postgres. Use [this file](https://raw.githubusercontent.com/thecartercenter/nemo/v6.11/config/database.yml.example) as a guide. The `test` and `development` blocks are not needed.
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
2. As root/privileged user: `sudo -u postgres psql nemo_production -c 'CREATE EXTENSION "uuid-ossp"'`
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

#### Upgrading to v9.11

1. As `deploy` user, run `nvm install 10.15.3` to update your node version. This may take a long time to compile if on a 32-bit x86 platform.

#### Upgrading to v9.13

1. As the root user, run `sudo -u postgres psql nemo_production -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto"'` to enable a new extension.

#### Upgrading to v9.16

1. The `uploads/questions/audio_prompts` directory must be renamed to `media_prompts`. If you are using cloud storage, this will need to be done via your cloud provider's console or API. If you are using local storage, this will be taken care of automatically.

#### Upgrading to v11.7

1. [Sentry](https://sentry.io/for/rails/) error tracking is now enabled by default. This means NEMO will automatically send us diagnostic logs when Rails errors occur. These error reports help us fix bugs faster, but may unintentionally reveal information to us about your servers or users. Please disable Sentry in `config/application.rb` (or switch to your own personal URL) if you wish to opt out.
    1. You can still configure the server to email you when errors occur via `config/local_config.rb`; this will not disable Sentry.

#### Upgrading to v11.11

1. Migrate any configs from `config/settings.local.yml` to `.env.production.local` (see `.env.development` for what the new keys should be named)

#### Upgrading to v12.0

See the [ActiveStorage Pull Request](https://github.com/thecartercenter/nemo/pull/802) for more details and tips for extremely large data sets.

1. Check out the final commit before switching to ActiveStorage, git tag `v12.0-step1`
1. Increase the thread pool in `database.yml` to 100 to allow parallelization (only needed if using cloud storage)
1. Run `rake db:migrate` to create new ActiveStorage tables and copy some data
1. Check out the latest commit on v12.0, git tag `v12.0-step2`
1. Run `rake db:migrate` to finish copying the data
1. Clean up: Decrease the thread pool in `database.yml` back to 5

#### Upgrading to v12.1

1. Prior to upgrading, if you have a `.env` or `.env.production` file prior to migrating, rename it to `.env.production.local`.
1. Check out tag `v12.1`.
1. If you have a custom theme, be sure to define `NEMO_CUSTOM_THEME_SITE_NAME` in `.env.production.local`. The `broadcast_tag` setting is no longer used (site_name is used instead).
1. Run `rake config:migrate`. Any previous setting values in `config/initializers/local_config.rb` should be copied to `.env.production.local` by the migration. The old `local_config.rb` file will remain for now, but it will not be used by the app and a deprecation notice will be added to the top.
1. Run `rake db:seed`.
1. You may delete the `local_config.rb`, `settings.local.yml`, `.rbenv-vars`, and `/config/settings/themes/custom.yml` files at this point, as everything is unified in `.env.*`.

#### Upgrading to v12.21

We've upgraded our node version to v16. After pulling the latest code:

1. Ensure you're using a recent version of yarn (such as v1.22), found via `yarn -v`
1. Run ```nvm install `cat .nvmrc` ``` (including the backticks) to upgrade
1. Run `nvm use` to switch
1. Run `rm -rf node_modules` to clean up
1. Run `yarn install` to install fresh
1. As the privileged user, run `sudo $EDITOR /etc/systemd/system/delayed-job.service` and completely overwrite it with the new contents of [delayed-job.service](/docs/delayed-job.service), then run `sudo systemctl daemon-reload`
1. Restart via `sudo systemctl restart delayed-job && sudo systemctl restart nginx` and everything should be working again

#### Upgrading to v12.26

(optional)

If you deployed the parallel deduplication change (v12.23)
and accepted ODK Collect responses on that version before deploying the related fix (v12.25),
you may want to set some environment variables and re-run the FixPartiallyProcessedResponses migration
to restore any answers that may not have fully processed. For example:

1. Deploy this version so the migration will initially run as a no-op and merely print metrics
2. `bundle exec rails db:migrate VERSION=20220328224830` # Rolls back to the necessary point in time
3. `NEMO_START_DATE=2022-02-24 NEMO_FINISH_DATE=2022-03-25 NEMO_REPOPULATE=1 bundle exec rails db:migrate:redo VERSION=20220328224830` # Migrates the data
4. `bundle exec rails db:migrate` # Rolls forward as needed

Set the above dates to whatever range is appropriate for your scenario.

#### Upgrading to v13.0

This is the first version of NEMO to include the option of using Enketo to submit/view/edit responses.
This includes a nested Node library to transform XML into JSON which must be installed separately:

1. `cd lib/enketo-transformer-service/`
2. `yarn install`
3. `cd ../..`
4. `bundle exec rake theme:preprocess` # Re-process CSS so things look right.

#### Upgrading to latest

1. Follow the 'General Upgrade Instructions' below.

#### General Upgrade Instructions

ssh to your server as the same root/privileged user used above. Then:

    sudo systemctl stop delayed-job && sudo systemctl stop nginx
    sudo su - deploy
    cd nemo
    nvm use # v8.12 or higher only

Make a backup of your database:

    mkdir -p tmp
    pg_dump nemo_production > tmp/`cat VERSION`-dump.sql
    ls -l tmp

Ensure that the dump file you created has non-zero size by looking in the directory listing.

Now, pull the latest code:

    git pull

If you want to upgrade to a particular version of NEMO, then try:

    git checkout vX.Y

where `X.Y` (or `X.Y.Z`) is the version number you want. Otherwise you should ensure you're on the `main` branch:

    git checkout main

If you get an error that `Your local changes to the following files would be overwritten by checkout`, you can usually
fix it by doing `git reset --hard`. This will wipe out any local changes to the code, which shouldn't be a problem
unless you changed it on purpose for some reason.

Then:

    bundle install --without development test --deployment
    bundle exec whenever -i nemo
    bundle exec rake assets:precompile
    bundle exec rake db:migrate
    bundle exec rake db:seed
    bundle exec rake config:migrate

Now check the commit history of [the `.env` default config file](https://github.com/thecartercenter/nemo/commits/main/.env)
(and older now-obsolete files such as [`local_config.rb.example`](https://github.com/thecartercenter/nemo/commits/main/config/initializers/local_config.rb.example) if necessary)
to see if anything needs to be updated in your local configuration.

Finally:

    exit # Back to privileged/root user
    sudo systemctl restart delayed-job && sudo systemctl restart nginx

Then load the site in your browser. You should see the new version number in the page footer.

### Troubleshooting

If the above is not successful, contact info@getnemo.org for assistance.
