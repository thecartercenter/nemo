# frozen_string_literal: true

require "fileutils"

namespace :theme do
  desc "Create a custom theme directory with example files."
  task init: :environment do
    begin
      Themeing::Initializer.new.run
    rescue ThemeDirExistsError
      abort("Existing theme directory detected. Aborting.")
    end
  end

  desc "Preprocess application.scss to create combinations for themes and LTR/RTL."
  task preprocess: :environment do
    Themeing::ScssPreprocessor.new.run
  end
end
