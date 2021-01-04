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

# Always need to preprocess SCSS things before precompiling.
Rake::Task["assets:precompile"].enhance(["theme:preprocess"])
