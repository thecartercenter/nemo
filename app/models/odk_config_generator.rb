class ODKConfigGenerator

  def generate_odk_config(username, password, site_url)
    string = generate_string(username, password, site_url)
    processed_string = Base64.strict_encode64(Zlib::Deflate.deflate(string))
    qrcode = RQRCode::QRCode.new(processed_string)
  end

  # Qs for tom: why no form? what is relationship to admin status?
  # size needs to be really large, doesn't seem right
  # confused about escaping the url - to_json doesn't escape forward slashes as in spec
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

    #'{"general":{"password":"%{password}","username":"%{username}","server_url":"%{site_url}"},"admin":{}}' % {password: password, username: username, site_url: escaped_site_url}
  end

end
