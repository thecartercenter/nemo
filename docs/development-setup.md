# NEMO Development Setup

### Package managers

Note to install the software below we recommend the following package managers:

- Mac OS X: Homebrew
- Linux/Unix: bundled package manager (e.g. apt-get, yum)

### Required software

1. Ruby
    - Use of [rbenv](https://github.com/rbenv/rbenv) is recommended.
    - Running `rbenv install` in the project root will install the version you need.
    - If not using `rbenv`, see the `.ruby-version` file in the project root to get the required version number.
    - Bundler is expected to be available. Run `gem install bundler` to install it.
1. Node
    - Use of [nvm](https://github.com/creationix/nvm#installation) is recommended.
        - Running `nvm install` in the project root will install the version you need.
        - Note that `nvm` does NOT shim Node executables so `nvm use` is required to load the right Node versions in each new shell session.
        - Alternatively, use can use e.g. `nvm alias default 10` to default to Node v10 in every new shell session.
    - If not using `nvm`, see the `.nvmrc` file in the project root to get the required version number.
    - The [`yarn`](https://yarnpkg.com/en/) executable must be in your PATH. To install it:
        - `brew install yarn` (on Mac)
        - `npm install -g yarn` (if you already have `npm`)
1. Memcached 1.4+
    - For development environments, caching is only needed if you are developing a feature that uses caching and want to test it.
    - In this case, be sure to increase the default slab page size. This is done by passing `-I 16m` to the `memcached` command.
    - When using Homebrew via `brew install memcached; brew services start memcached`, slab size can be configured at `/usr/local/Cellar/memcached/1.x.x/homebrew.mxcl.memcached.plist`
1. PostgreSQL 10+
    - Create empty databases for use by the app: `createdb nemo_development && createdb nemo_test`
1. ImageMagick 6.7+
    - ImageMagick is used to resize uploaded images.
    - It should be available through any of the package managers listed above. If not it can be built from source.
1. Chrome (Browser) 76+
    - Used for automated browser testing.
1. GraphViz 2.36+
    - [GraphViz](http://graphviz.org/) is used to visualize the relationships between data in the database.

### Linters

Linters are strongly recommended for checking your code before opening a PR. The CI system will run linters as well and your PR won't be approved until all issues are resolved or cancelled by the reviewer.

#### Setup

The below assume you have installed the Ruby and Node versions specified in `.ruby-version` and `.nvmrc` files, respectively.

Once you have `nvm` and Node installed, the following lines should give you all the required linters:

```
nvm use
gem install rubocop -v 0.52.0
gem install scss_lint -v 0.56.0
```

#### Running

To lint your code, simply run:

```
bin/lint
```

This will examine any modified or untracked files in your working copy.

To instead examine any new or modified files in your branch (not including uncommitted changes), run:

```
bin/lint --branch
```

The latter should be run before opening a pull request.

As part of an effort to clean up old code, you should try to resolve any linter errors in files you touch, unless there are an overwhelming number of them. At bare minimum, the _lines_ you touch should not have any lint.

#### Auto-fixing

Many lints can be automatically fixed. The following commands can help, depending on what type of file you're linting:

- `rubocop --auto-correct file.rb`
- `yarn run lint:js --fix file.js`
- `yarn run lint:scss --fix file.scss`

#### Tools

Most code editors have plugins for linting. They will identify and let you click directly into problematic lines. You are encouraged to try one out!

For Atom, install the `linter` package which contains shared stuff, then:

* `linter-eslint`
    * For this one, set your Global Node Installation Path and check the 'Use global ESLint installation' box.
* `linter-rubocop`
* `linter-scss-lint`

### Running the app

#### Retrieve project files using Git

```
git clone https://github.com/thecartercenter/nemo.git
cd nemo
```

If developing, it's best to work off the development branch:

```
git checkout develop
```

#### Bundle, configure, and load schema

1. Install the required gems by running `bundle install` in the project directory.
1. Install the required Node modules by running `yarn install` in the project directory.
1. Install Enketo's required Node modules by running `yarn install` in the `lib/enketo-transformer-service/` directory.
    1. TODO: Make this happen automatically during the previous step, maybe with Yarn workspaces.
1. Run `cp config/database.yml.example config/database.yml`.
1. (Optional) Create a `.env.development.local` file and override any settings from `.env` as you see fit. Note that a valid Google Maps API key must be present for certain tests to pass.
1. Setup the UUID postgres extension:
    1. On Linux: `sudo -u postgres psql nemo_development -c 'CREATE EXTENSION "uuid-ossp"'`
    1. On Mac with Homebrew: `psql nemo_development -c 'CREATE EXTENSION "uuid-ossp"'`
1. Load the database schema: `bundle exec rake db:schema:load`.
1. Seed the database: `bundle exec rake db:seed`.
1. Pre-process the theme SCSS files: `bundle exec rake theme:preprocess`
1. Create an admin account: `bundle exec rake db:create_admin`. You should receive a message like this: "Admin user created with username admin, password hTyWc9Q6" (The password is random, copy it and use on your first login).
1. Optionally, you can create some fake data to get things rolling by running `bundle exec rake db:create_fake_data`.

#### Run the tests

1. Run `nvm use` to ensure you have the right version of Node.js loaded. Do this once per console session.
1. Run `rspec` to test Rails.
    * All tests should pass. Running them takes about 10-15 minutes.
    * If you have trouble debugging a feature spec, you can run it headed (so you can watch the browser go through the spec) by doing `HEADED=1 bundle exec rspec spec/features/your_spec.rb`.
1. Run `yarn test` to test React components.
    * These rely on separately compiled i18n translations which can be generated via `rails i18n:js:export`
    * Update snapshots and re-run on change: `yarn test -u --watch`

#### Start the server

For a development setup, run `nvm use && rails s`.
You may want to run `bundle exec rake db:create_fake_data` to create a sample mission.

#### Login

1. Navigate to http://localhost:3000
1. Login with username **admin** and use the random password that was generated when you ran `bundle exec rake db:create_admin` (make sure to change the password after login).
1. Create a new Mission and get started making forms!

### Dealing with JavaScript

NEMO includes several React components that are provided via [react-rails](https://github.com/reactjs/react-rails).

### Migrations

Database schema migrations can be run with `rails db:migrate`.
You'll also need to run `rails db:test:prepare` for specs to pass.

### Delayed Job Operations

Operations like data import run asynchronously using a background tool called delayed_job.
You can run this locally via `bin/delayed_job start`.

To log output from these background jobs, you can use `Delayed::Worker.logger.info("foo")` and
view `log/dj.log` within a few minutes (the log file doesn't always update immediately).

### Testing with ODK Collect

#### Using NEMO live

1. Download the Collect app onto your Android device or run it on an emulator
    - https://opendatakit.org/
1. Configure your rails development server so Collect can find it
    - Option A:
        - Run `./bin/server -b 0.0.0.0` to expose NEMO on a local network
        - Allow your emulator to access local ports: `adb reverse tcp:8443 tcp:8443`
    - Option B:
        - Run `ngrok http 8443` to expose NEMO publicly
        - Allow the ngrok host to serve Rails by adding `config.hosts << "YOUR_ID.ngrok.io"` to `development.rb`, then restart NEMO
1. Make your form live in NEMO
1. Point Collect to your development server
    - In Collect, go to `General Settings > Platform Settings > URL`
    - For the URL put: `http://YOUR_IP:8443/m/your_mission` or `https://YOUR_ID.ngrok.io/m/your_mission`, replacing `YOUR_IP` with `0.0.0.0` or equivalent (from option A), or `YOUR_ID` with the ID provided by ngrok (from option B)
    - Put in your username and password
1. Retrieve Form
    - In Collect, you should now be able to go to `Get Blank Form` to download the forms from NEMO
    - If it fails, try restarting the server to make sure any config changes above were applied. Then check the server logs to make sure the connection is really going through.
1. If the form doesn't work right, look at xml directly by adding `.xml` to the URL path, e.g. <http://nemo.test/en/m/sandbox/forms/form-123.xml>

#### Using hardcoded forms

See also [ODK docs](https://docs.getodk.org/collect-forms/#loading-forms-directly).

1. Download example form from <https://github.com/opendatakit/sample-forms>
1. Send to your device: `adb push myform.xml /sdcard/Android/data/org.odk.collect.android/files/projects/12345/forms/`
1. Try out form, make changes, repeat.

#### Viewing Collect error logs

Sometimes, the Collect app has an error downloading/uploading but doesn't display the actual error message to the user.
These errors can be extremely hard to diagnose. You can find the raw device logs by either:

1. Use a USB cable to physically connect a phone running the production Collect app to your laptop and use `adb logcat` from your terminal
   1. Note: These logs will be limited and hard to parse without the source code
2. Run Collect from source by following the instructions at https://github.com/getodk/collect
   1. In short: clone the repo and run it on an emulator via Android Studio
   2. Note: It's best to debug from the latest public release (e.g. `git checkout v2021.3.2`) rather than from their main branch which may have active issues
   3. Note: These logs will be more useful than USB debugging, and point directly to source code with more context. You can also modify the source code in order to provide more context, pause at breakpoints to step through the code, etc.

Note: from one year to another, the Android ecosystem changes and Collect also modifies their architecture. They don't always document upgrade instructions very clearly,
so ODK's #collect-code Slack channel can be a good place to get help with error messages on upgrade if you can't figure out what's wrong.

### Upgrading Enketo

Enketo uses jQuery under the hood, and it's important to keep library versions consistent so there aren't conflicts.
To upgrade our version of Enketo:
1. Check their [changelog](https://github.com/enketo/enketo-core/blob/master/CHANGELOG.md)
2. Update `package.json` (enketo-core, possibly jquery) and `lib/enketo-transformer-service/package.json` (enketo-transformer) as appropriate
3. Verify that the changes in `yarn.lock` seem valid (e.g. we don't suddenly have TWO different versions of jQuery floating around)
4. Restart the dev server

### Troubleshooting

#### Integrity check failed

If you ever see `check_yarn_integrity error Integrity check failed` or `Your Yarn packages are out of date!`
simply follow the instructions by running `yarn install --check-files`.
Note if you previously ran `yarn install` with a different version of Node, the integrity check will fail.
If you frequently see this error, make sure you execute `nvm use` before `yarn install`.

#### i18n/translations issues

If you ever see `Missing file extension for "../assets/javascripts/i18n/translations"` or similar,
make sure you've run `rails i18n:js:export` in order to provide the translations files to JS scripts.
