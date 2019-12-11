# frozen_string_literal: true

module ODK
  class UserConfigEncoder
    def initialize(username, password, site_url)
      @username = username
      @password = password
      @site_url = site_url
    end

    def encode_config
      hash = {
        general: {
          password: @password,
          username: @username,
          server_url: @site_url
        },
        admin: {}
      }
      Base64.strict_encode64(Zlib::Deflate.deflate(hash.to_json))
    end
  end
end
