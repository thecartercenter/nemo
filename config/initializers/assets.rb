# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile.concat(%w[
  application_nemo_ltr.css
  application_elmo_ltr.css
  application_nemo_rtl.css
  application_elmo_rtl.css
])

Rails.application.config.assets.precompile << "disable_bootstrap_modal_transitions.css" if Rails.env.test?
