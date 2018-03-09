# frozen_string_literal: true

module Themeing
  # Copies the default theme assets to the /theme directory as examples.
  class Initializer
    def run
      abort("Existing theme directory detected. Aborting.") if Dir.exist?(Rails.root.join("theme"))
      puts "Creating theme directory."
      FileUtils.mkdir_p(Rails.root.join("theme", "logos"))
      FileUtils.cp(default_scss, Rails.root.join("theme", "styles.scss"))
      FileUtils.cp(light_logo, Rails.root.join("theme", "logos", "light.png"))
      FileUtils.cp(dark_logo, Rails.root.join("theme", "logos", "dark.png"))
    end

    private

    def default_scss
      Rails.root.join("app", "assets", "stylesheets", "all", "themes", "_nemo_theme.scss")
    end

    def logo_dir
      Rails.root.join("app", "assets", "images", "logos", "nemo")
    end

    def light_logo
      Rails.root.join(logo_dir, "light.png")
    end

    def dark_logo
      Rails.root.join(logo_dir, "dark.png")
    end
  end
end
