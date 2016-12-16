module LogoHelper
  def logo_image(options = {})
    if configatron.has_key?(:logo_path)
      image_tag(configatron.logo_path, options)
    else
      image_tag("logo.png", options)
    end
  end

  def logo_dark_image(options = {})
    if configatron.has_key?(:logo_dark_path)
      image_tag(configatron.logo_dark_path, options)
    else
      image_tag("logo-dark.png", options)
    end
  end
end
