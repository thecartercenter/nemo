module GeneralSpecHelpers
  # Encodes credentials for basic auth
  def encode_credentials(username, password)
    "Basic #{Base64.encode64("#{username}:#{password}")}"
  end

  # helper method to parse json and make keys symbols
  def parse_json(body)
    JSON.parse(body, symbolize_names: true)
  end
end