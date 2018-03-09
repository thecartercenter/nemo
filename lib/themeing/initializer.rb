# frozen_string_literal: true

module Themeing
  # Copies the default theme assets to the /theme directory as examples.
  class Initializer
    include PathHelpers

    def run
      abort_if_theme_dir_exists
      puts "Creating theme directory."
      FileUtils.mkdir_p(src_logo_dir)
      FileUtils.cp(default_scss, src_scss)
      FileUtils.cp(default_light_logo, src_light_logo)
      FileUtils.cp(default_dark_logo, src_dark_logo)
    end
  end
end
