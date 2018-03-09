# frozen_string_literal: true

module Themeing
  # Copies the user defined themes into appropriate locations.
  class Installer
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

    def theme_dir_present?
      Dir.exist?(Rails.root.join("theme"))
    end

    def clear_theme
      puts "No theme directory found. Removing any old style assets."
      FileUtils.rm_rf(dest_scss)
      FileUtils.rm_rf(dest_logo_dir)
    end

    def install_theme
      FileUtils.mkdir_p(dest_logo_dir)
      copy_with_message(src_scss, dest_scss)
      copy_with_message(src_light_logo, dest_light_logo)
      copy_with_message(src_dark_logo, dest_dark_logo)
    end

    def copy_with_message(src, dest)
      puts "Copying #{src} to #{dest}"
      FileUtils.cp(src, dest)
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

    def dest_scss
      @dest_scss ||= Rails.root.join("app", "assets", "stylesheets", "all", "themes", "_custom_theme.scss")
    end

    def dest_logo_dir
      @dest_logo_dir ||= Rails.root.join("app", "assets", "images", "logos", "custom")
    end

    def dest_light_logo
      @dest_light_logo ||= Rails.root.join(dest_logo_dir, "light.png")
    end

    def dest_dark_logo
      @dest_dark_logo ||= Rails.root.join(dest_logo_dir, "dark.png")
    end

    def src_scss
      @src_scss ||= Rails.root.join("theme", "styles.scss")
    end

    def src_logo_dir
      @src_logo_dir ||= Rails.root.join("theme", "logos")
    end

    def src_light_logo
      @src_light_logo ||= Rails.root.join(src_logo_dir, "light.png")
    end

    def src_dark_logo
      @src_dark_logo ||= Rails.root.join(src_logo_dir, "dark.png")
    end
  end
end
