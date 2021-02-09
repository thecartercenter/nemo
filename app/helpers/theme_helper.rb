# frozen_string_literal: true

# Methods relating to theme and direction customization.
module ThemeHelper
  DEFAULT_THEME = "nemo"
  DEFAULT_DIRECTION = "ltr"

  def current_direction
    Cnfg.rtl_locales.include?(I18n.locale) ? "rtl" : "ltr"
  end

  def stylesheet_files
    [
      "application_#{current_mission_config.theme}_#{current_direction}",
      "application_#{DEFAULT_THEME}_#{current_direction}",
      "application_#{DEFAULT_THEME}_#{DEFAULT_DIRECTION}"
    ]
  end

  # Returns a link tag for the appropriate combination of direction (ltr/rtl) and theme.
  # If the desired file is missing, returns the default.
  # If default is missing, raises an error.
  def main_stylesheet_tag(params = {})
    media = params[:medium] || "all"
    style_dir = Rails.root.join("app/assets/stylesheets")
    stylesheet_files.each do |file|
      return stylesheet_link_tag(file, media: media) if File.exist?(style_dir.join("#{file}.scss"))
    end
    raise "Processed SCSS files not found. Try: bundle exec rake theme:preprocess"
  end

  # Returns an image tag for the logo for the requested style and the current theme.
  def logo_image(style: :light, **options)
    image_tag("logos/#{current_mission_config.theme}/#{style}.png", **options)
  end
end
