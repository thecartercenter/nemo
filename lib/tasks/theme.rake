# frozen_string_literal: true

require "fileutils"

namespace :theme do
  desc "Create a custom theme directory with example files."
  task init: :environment do
    abort("Existing theme directory detected. Aborting.") if File.exist?(Rails.root.join("theme"))
    scss = Rails.root.join("app", "assets", "stylesheets", "all", "themes", "_nemo_theme.scss")
    logo_dir = Rails.root.join("app", "assets", "images", "logos", "nemo")
    light_logo = Rails.root.join(logo_dir, "light.png")
    dark_logo = Rails.root.join(logo_dir, "dark.png")

    FileUtils.mkdir_p(Rails.root.join("theme", "logo"))
    FileUtils.cp(scss, Rails.root.join("theme", "styles.scss"))
    FileUtils.cp(light_logo, Rails.root.join("theme", "logo", "light.png"))
    FileUtils.cp(dark_logo, Rails.root.join("theme", "logo", "dark.png"))
  end
end
