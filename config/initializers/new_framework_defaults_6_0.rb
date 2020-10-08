# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 6.0 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# Embed purpose and expiry metadata inside signed and encrypted
# cookies for increased security.
#
# This option is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.0.
Rails.application.config.action_dispatch.use_cookies_with_metadata = false # New default is true

# Use ActionMailer::MailDeliveryJob for sending parameterized and normal mail.
#
# The default delivery jobs (ActionMailer::Parameterized::DeliveryJob, ActionMailer::DeliveryJob),
# will be removed in Rails 6.1. This setting is not backwards compatible with earlier Rails versions.
# If you send mail in the background, job workers need to have a copy of
# MailDeliveryJob to ensure all delivery jobs are processed properly.
# Make sure your entire app is migrated and stable on 6.0 before using this setting.
Rails.application.config.action_mailer.delivery_job = "ActionMailer::DeliveryJob" # New default is "ActionMailer::MailDeliveryJob"

# Enable the same cache key to be reused when the object being cached of type
# `ActiveRecord::Relation` changes by moving the volatile information (max updated at and count)
# of the relation's cache key into the cache version to support recycling cache key.
Rails.application.config.active_record.collection_cache_versioning = false # New default is true
