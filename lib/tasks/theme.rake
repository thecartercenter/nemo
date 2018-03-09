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

  desc "Migrates old theme setup to new one."
  task migrate: :environment do
    Themeing::Migrator.new.run
  end
end
