# frozen_string_literal: true

module Themeing
  # Various paths needed for themeing.
  module PathHelpers
    private

    def abort_if_theme_dir_exists
      abort("Existing theme directory detected. Aborting.") if theme_dir_present?
    end

    def theme_dir_present?
      Dir.exist?(theme_dir)
    end

    def theme_dir
      Rails.root.join("theme")
    end

    def tmp_dir
      Rails.root.join("tmp")
    end

    def theme_trash_dir
      tmp_dir.join("old-theme")
    end

    def styles_dir
      @styles_dir ||= Rails.root.join("app/assets/stylesheets")
    end

    def images_dir
      @images_dir ||= Rails.root.join("app/assets/images")
    end

    def theme_scss_dir
      styles_dir.join("themes")
    end

    def installed_scss
      @installed_scss ||= Rails.root.join("app/assets/stylesheets/themes/_custom_theme.scss")
    end

    def installed_settings
      @installed_settings ||= Rails.root.join("config/settings/themes/custom.yml")
    end

    def logos_dir
      @logos_dir ||= images_dir.join("logos")
    end

    def installed_logo_dir
      @installed_logo_dir ||= logos_dir.join("custom")
    end

    def installed_light_logo
      @installed_light_logo ||= Rails.root.join(installed_logo_dir, "light.png")
    end

    def installed_dark_logo
      @installed_dark_logo ||= Rails.root.join(installed_logo_dir, "dark.png")
    end

    def src_scss
      @src_scss ||= Rails.root.join("theme/styles.scss")
    end

    def src_settings
      @src_settings ||= Rails.root.join("theme/settings.yml")
    end

    def src_logo_dir
      @src_logo_dir ||= Rails.root.join("theme/logos")
    end

    def src_light_logo
      @src_light_logo ||= Rails.root.join(src_logo_dir, "light.png")
    end

    def src_dark_logo
      @src_dark_logo ||= Rails.root.join(src_logo_dir, "dark.png")
    end

    def default_scss
      theme_scss_dir.join("_nemo_theme.scss")
    end

    def default_logo_dir
      logos_dir.join("nemo")
    end

    def default_light_logo
      Rails.root.join(default_logo_dir, "light.png")
    end

    def default_dark_logo
      Rails.root.join(default_logo_dir, "dark.png")
    end

    def copy_with_message(src, dest)
      puts "Copying #{src} to #{dest}"
      FileUtils.cp(src, dest)
    end
  end
end
