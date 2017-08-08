class ODKConfigGenerator

  def generate_odk_config(username, password, site_url)
    string = generate_string(username, password, site_url)
    processed_string = Base64.strict_encode64(Zlib::Deflate.deflate(string))
    qrcode = RQRCode::QRCode.new(processed_string)
  end

  def generate_string(username, password, site_url)
    hash = {
      general: {
        password: password,
        username: username,
        server_url: site_url
      },
      admin: {}
    }
    hash.to_json
  end
end
