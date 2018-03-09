# frozen_string_literal: true

module Themeing
  # Checks for an old-style custom theme and migrates to the new style.
  class Migrator
    include PathHelpers

    OLD_NEMO_LOGO_FILE_SIZE = 7995

    def run
      return if theme_dir_present?
      return unless old_light_logo_exists?
      
      if File.size(old_light_logo) == OLD_NEMO_LOGO_FILE_SIZE
        handle_nemo_theme
      else
        handle_custom_theme
      end
      remove_old_assets
      end
    end

    private

    def handle_nemo_theme
      # Don't need to copy these since they're now built into the system.
      remove_old_assets
      create_temp_theme_flag("nemo")
    end

    def handle_custom_theme
      # Custom SCSS is required, else we revert to nemo.
      if File.exist?(old_custom_scss_path)
        copy_old_assets
        create_temp_theme_flag("custom")
      else
        create_temp_theme_flag("nemo")
      end
    end

    def copy_old_assets
      FileUtils.mkdir_p(src_logo_dir)
      copy_with_message(old_custom_scss_path, src_scss)
      copy_with_message(old_light_logo, src_light_logo)
      if old_dark_logo_exists?
        copy_with_message(old_dark_logo, src_dark_logo)
      else
        copy_with_message(default_dark_logo, src_dark_logo)
      end
    end

    def remove_old_assets
      puts "Removing any assets from old theme configuration."
      FileUtils.rm_rf(old_custom_scss_path)
      FileUtils.rm_rf(old_light_logo)
      FileUtils.rm_rf(old_dark_logo) if old_dark_logo_exists?
    end

    def old_custom_scss_path
      Rails.root.join("app", "assets", "stylesheets", "all", "variables", "_theme.scss")
    end

    def old_light_logo
      configatron.key?(:logo_path) ? Rails.root.join(configatron.logo_path) : nil
    end

    def old_light_logo_exists?
      old_light_logo && File.exist?(old_light_logo)
    end

    def old_dark_logo
      configatron.key?(:logo_dark_path) ? Rails.root.join(configatron.logo_dark_path) : nil
    end

    def old_dark_logo_exists?
      old_dark_logo && File.exist?(old_dark_logo)
    end

    def create_temp_theme_flag(theme)
      FileUtils.mkdir_p(tmp_dir)
      File.open(tmp_dir.join("theme_flag"), "w") { |f| f.write(theme) }
    end
  end
end
