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

  def media_fixture(name)
    File.open(fixture("media", name))
  end

  def audio_fixture(name)
    fixture("media", "audio", name)
  end

  def option_set_fixture(name)
    File.open(fixture("option_set_imports", name))
  end

  def user_batch_fixture(name)
    File.open(fixture("user_batches", name))
  end

  # `substitutions` should be a hash of arrays.
  # For each hash pair, e.g. `grp: groups_ids`, the method substitutes
  # e.g. `*grp8*` in the file with `groups_ids[7]`.
  def prepare_expectation(filename, substitutions)
    expectation_file(filename).tap do |contents|
      substitutions.each do |key, values|
        values.each_with_index do |value, i|
          contents.gsub!("*#{key}#{i + 1}*", value.to_s)
        end
      end
    end
  end

  def in_timezone(tz)
    old_tz = Time.zone
    Time.zone = tz
    yield
    Time.zone = old_tz
  end

  def tidyxml(str)
    Nokogiri::XML(str) { |config| config.noblanks }.to_s
  end

  # assigns ENV vars
  def with_env(vars)
    vars.each_pair { |k, v| ENV[k] = v }
    yield
  ensure
    vars.each_pair { |k, _| ENV.delete(k) }
  end

  private

  def fixture(*dirs, name)
    dir = dirs.is_a?(Array) ? dirs.join("/") : dirs

    path = Rails.root.join("spec/fixtures/#{dir}/#{name}")
  end
end
