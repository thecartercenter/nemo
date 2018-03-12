# frozen_string_literal: true

module Themeing
  # Copies the user defined themes into appropriate locations.
  class Installer
    include PathHelpers

    def run
      if theme_dir_present?
        check_for_required_files
        install_theme
      else
        clear_theme
      end
      puts "Running theme:preprocess"
      ScssPreprocessor.new.run
    end

    private

    def clear_theme
      puts "No theme directory found. Removing any old style assets."
      FileUtils.rm_rf(installed_scss)
      FileUtils.rm_rf(installed_settings)
      FileUtils.rm_rf(installed_logo_dir)
    end

    def install_theme
      FileUtils.mkdir_p(installed_logo_dir)
      copy_with_message(src_scss, installed_scss)
      copy_with_message(src_settings, installed_settings)
      copy_with_message(src_light_logo, installed_light_logo)
      copy_with_message(src_dark_logo, installed_dark_logo)
    end

    def check_for_required_files
      if !File.exist?(src_scss)
        abort("You must include a theme style file at #{src_scss_path}")
      elsif !File.exist?(src_light_logo)
        abort("You must include a light-style logo at #{src_light_logo}")
      elsif !File.exist?(src_dark_logo)
        abort("You must include a dark-style logo at #{src_dark_logo}")
      end
    end
  end
end
