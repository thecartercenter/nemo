## Cloning an Instance in AWS

1. Make an AMI (Actions > Image > Create Image)
2. AMI > Launch
    1. Protect termination
    2. Enable T2/T3 unlimited
    3. Storage: more for DB instance, less for BG instance.
    3. Security groups
        1. Allow SSH from all
        2. Allow all traffic from VPC (default VPC group)
3. Don't set up elastic IP unless it's a web instance (AWS limits number of elastic IPs)
4. Give instance a name like `nemo-staging-db`.
3. Copy public IP and add to your `~/.ssh/config` with helpful alias.
4. If you are moving your background job processing to a different server, do
        sudo -u deploy crontab -r
    to delete the whenever-created crontab, which is no longer needed on this server.

## Setting up DB Instance

### Configure access to DB Instance

1. `sudo -u deploy crontab -r` to delete the whenever-created crontab, no longer needed.
1. `sudo systemctl stop nginx && sudo systemctl disable nginx`
1. `sudo vi /etc/postgresql/10/main/postgresql.conf` and set `listen_addresses = '*'`
1. `sudo vi /etc/postgresql/10/main/pg_hba.conf` and add these lines:

        # IPv4 remote connections:
        host    all             all             0.0.0.0/0               md5
        # IPv6 remote connections:
        host    all             all             ::/0                    md5
1. `sudo systemctl restart postgresql`
1. Set password for `deploy` user in `nemo_production` database (on database instance, privileged user):
        sudo su - deploy
        psql nemo_production
        \password # and enter new password
        \quit
        exit

### Setup DB connection on web instance

1. Verify connection is possible:
        psql -h <DB_INST_PRIV_DNS> -U deploy nemo_production
    Enter the password. Console should open successfully.
2. Edit `config/database.yml` and make it look something like this:
        default: &default
          adapter: postgresql
          encoding: utf8
          pool: 5

        production:
          <<: *default
          database: nemo_production
          host: <DB_INST_PRIV_DNS>
          username: deploy
          password: "<DB_PASSWORD>"
    (Note quotes around password, just to be safe).
3. Restart nginx and ensure site still works.
4. Disable local postgres:
        sudo systemctl stop postgresql && sudo systemctl disable postgresql

## Setting up background worker instance

1. Clone app instance per instructions above.
1. Do steps under "Setup DB connection on web instance" above.
2. Disable local nginx:
        sudo systemctl stop nginx && sudo systemctl disable nginx
2. Open rails console and ensure a basic query (e.g. `User.count`) works.

## Sample Capistrano config

If using capistrano for deployment, configure something like this:

    set :deploy_to, "/u/apps/nemo"
    set :rbenv_custom_path, "/opt/rbenv"

    set :whenever_roles, %i[bg] # Only deploy schedule.rb jobs to crontab on bg server(s).
    set :delayed_job_roles, %i[bg] # Only deploy run delayed_job on bg server(s).
    set :delayed_job_workers, 2

    server "1.2.3.4", user: "deploy", roles: %i[app web]
    server "1.2.3.5", user: "deploy", roles: %i[db]
    server "1.2.3.6", user: "deploy", roles: %i[bg]
