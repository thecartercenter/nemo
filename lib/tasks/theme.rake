# frozen_string_literal: true

require "fileutils"

namespace :theme do
  desc "Create a custom theme directory with example files."
  task init: :environment do
    Themeing::Initializer.new.run
  end

  desc "Preprocess application.scss to create combinations for themes and LTR/RTL."
  task preprocess: :environment do
    Themeing::ScssPreprocessor.new.run
  end

  desc "Copies custom theme files into appropriate locations."
  task install: :environment do
    Themeing::Installer.new.run
  end
end

Rake::Task["assets:precompile"].clear
namespace :assets do
  # Note: Copied from capistrano-rails v1.7.0 and modified to add `env -i`
  task :precompile do
    on release_roles(fetch(:assets_roles)) do
      within release_path do
        with rails_env: fetch(:rails_env), rails_groups: fetch(:rails_assets_groups) do
          # execute :rake, "assets:precompile"

          execute :env, "-i", "NODE_ENV=#{fetch(:node_env)}", "RAILS_ENV=#{fetch(:rails_env)}", :rake, "assets:precompile"

          # execute :env, "-i",
          #         "PATH=/usr/bin:/bin",
          #         "HOME=#{fetch(:deploy_to)}",
          #         "RAILS_ENV=#{fetch(:rails_env)}",
          #         "NODE_ENV=production",
          #         :bundle, :exec, :rake, "assets:precompile"
        end
      end
    end
  end
end

# Always need to preprocess SCSS things before precompiling.
Rake::Task["assets:precompile"].enhance(["theme:preprocess"])
