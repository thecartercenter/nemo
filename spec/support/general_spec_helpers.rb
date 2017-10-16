module GeneralSpecHelpers
  # Encodes credentials for basic auth
  def encode_credentials(username, password)
    "Basic #{Base64.encode64("#{username}:#{password}")}"
  end

  # helper method to parse json and make keys symbols
  def parse_json(body)
    JSON.parse(body, symbolize_names: true)
  end

  # reads a file from spec/expectations
  def expectation_file(filename)
    File.read(Rails.root.join("spec", "expectations", filename))
  end

  def in_timezone(tz)
    old_tz = Time.zone
    Time.zone = tz
    yield
    Time.zone = old_tz
  end
end
