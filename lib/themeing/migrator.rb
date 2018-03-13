# frozen_string_literal: true

module Themeing
  # Checks for an old-style custom theme and migrates to the new style.
  class Migrator
    include PathHelpers

    OLD_NEMO_LOGO_FILE_SIZE = 7995

    def run
      puts "Checking for old theme setup."
      if theme_dir_present?
        puts "theme dir is present, skipping old theme check."
        return
      end
      unless old_light_logo_exists?
        if old_light_logo.nil?
          puts "Old logo setting not found, done."
        else
          puts "Old logo file not found at #{old_light_logo}, done."
        end
        return
      end

      if File.size(old_light_logo) == OLD_NEMO_LOGO_FILE_SIZE
        handle_nemo_theme
      else
        handle_custom_theme
      end
      remove_old_assets
    end

    private

    def handle_nemo_theme
      # Don't need to copy these since they're now built into the system.
      puts "Detected NEMO theme, which is new default. Setting flag and deleting custom assets."
      create_temp_theme_flag("nemo")
    end

    def handle_custom_theme
      # Custom SCSS is required, else we revert to nemo.
      puts "Detected custom theme. Migrating."
      if File.exist?(old_custom_scss_path)
        copy_old_assets
        puts "Installing theme."
        Installer.new.run
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
      File.open(src_settings, "w") { |f| f.write("site_name: #{configatron.site_name}\n") }
    end

    def remove_old_assets
      puts "Moving any assets from old theme configuration to tmp/old-theme dir."
      FileUtils.mkdir_p(theme_trash_dir)
      FileUtils.mv(old_custom_scss_path, theme_trash_dir.join("styles.scss"))
      FileUtils.mv(old_light_logo, theme_trash_dir.join("light.png"))
      FileUtils.mv(old_dark_logo, theme_trash_dir.join("dark.png")) if old_dark_logo_exists?
    end

    def old_custom_scss_path
      Rails.root.join("app", "assets", "stylesheets", "all", "variables", "_theme.scss")
    end

    def old_light_logo
      configatron.key?(:logo_path) ? images_dir.join(configatron.logo_path) : nil
    end

    def old_light_logo_exists?
      old_light_logo && File.exist?(old_light_logo)
    end

    def old_dark_logo
      configatron.key?(:logo_dark_path) ? images_dir.join(configatron.logo_dark_path) : nil
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
