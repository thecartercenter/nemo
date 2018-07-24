module GeneralSpecHelpers
  # Encodes credentials for basic auth
  def encode_credentials(username, password)
    "Basic #{Base64.encode64("#{username}:#{password}")}"
  end

  # helper method to parse json and make keys symbols
  def parse_json(body)
    JSON.parse(body, symbolize_names: true)
  end

  # reads a file from spec/fixtures
  def fixture_file(filename)
    File.read(Rails.root.join("spec", "fixtures", filename))
  end

  def media_fixture(name)
    fixture("media", name)
  end

  def audio_fixture(name)
    fixture("media", "audio", name)
  end

  def option_set_fixture(name)
    fixture("option_set_imports", name)
  end

  def user_batch_fixture(name)
    fixture("user_batches", name)
  end

  # Accepts a fixture filename and form provided by a spec, and creates xml mimicking odk
  def prepare_odk_fixture(filename, path, form, options = {})
    items = form.preordered_items.map { |i| Odk::DecoratorFactory.decorate(i) }
    nodes = items.map(&:preordered_option_nodes).uniq.flatten
    xml = prepare_fixture(path,
      formname: [form.name],
      form: [form.id],
      formver: options[:formver].present? ? [options[:formver]] : [form.code],
      itemcode: items.map(&:odk_code),
      itemqcode: items.map(&:code),
      optcode: nodes.map(&:odk_code),
      optsetid: items.map(&:option_set_id).compact.uniq,
      questionid: items.map { |i| i.question&.id },
      value: options[:values].presence || [])
    if save_fixtures
      dir = Rails.root.join("tmp", path)
      FileUtils.mkdir_p(dir)
      File.open(dir.join(filename), "w") { |f| f.write(xml) }
    end
    xml
  end

  # `substitutions` should be a hash of arrays.
  # For each hash pair, e.g. `grp: groups_ids`, the method substitutes
  # e.g. `*grp8*` in the file with `groups_ids[7]`.
  def prepare_fixture(filename, substitutions)
    fixture_file(filename).tap do |contents|
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
    Nokogiri::XML(str, &:noblanks).to_s
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
    File.open(path)
  end
end
