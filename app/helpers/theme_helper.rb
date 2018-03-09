# frozen_string_literal: true

# Methods relating to theme and direction customization.
module ThemeHelper
  DEFAULT_THEME = "nemo"
  DEFAULT_DIRECTION = "ltr"

  def current_theme
    configatron.key?(:theme) ? configatron.theme : DEFAULT_THEME
  end

  def current_direction
    I18n.t("locale_dir", default: "ltr")
  end

  # Returns a link tag for the appropriate combination of direction (ltr/rtl) and theme.
  # If the desired file is missing, returns the default.
  # If default is missing, raises an error.
  def main_stylesheet_tag
    to_try = [
      "application_#{current_theme}_#{current_direction}",
      "application_#{DEFAULT_THEME}_#{current_direction}",
      "application_#{DEFAULT_THEME}_#{DEFAULT_DIRECTION}"
    ]
    style_dir = Rails.root.join("app", "assets", "stylesheets")
    to_try.each do |file|
      return stylesheet_link_tag(file, media: "all") if File.exist?(style_dir.join("#{file}.scss"))
    end
    raise "Processed SCSS files not found. Did you run the pre-processor? See documentation."
  end

  # Returns an image tag for the logo for the requested style and the current theme.
  def logo_image(style: :light, **options)
    image_tag("logos/#{current_theme}/#{style}.png", **options)
  end
end
