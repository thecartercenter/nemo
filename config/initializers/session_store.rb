# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
ELMO::Application.config.session_store :cookie_store, key: 'elmo_session', secure: Rails.env.production?, expire_after: 1.day
