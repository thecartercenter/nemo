# frozen_string_literal: true

module GeneralSpecHelpers
  # Encodes credentials for basic auth
  def encode_credentials(username, password)
    "Basic #{Base64.encode64("#{username}:#{password}")}"
  end

  # helper method to parse json and make keys symbols
  def parse_json(body)
    JSON.parse(body, symbolize_names: true)
  end

  # This is an override that allows the original syntax as well as a new syntax
  # in which the first argument is the Class on which the constant is defined.
  # This allows the class to be autoloaded, working around a common pitfall.
  def stub_const(full_name_or_class, val_or_name, val = nil)
    if val
      super("#{full_name_or_class.name}::#{val_or_name}", val)
    else
      super(full_name_or_class, val_or_name)
    end
  end

  # reads a file from spec/fixtures
  def fixture_file(filename)
    File.read(Rails.root.join("spec/fixtures", filename))
  end

  def media_fixture(name)
    fixture("media", name)
  end

  def audio_fixture(name)
    fixture("media", "audio", name)
  end

  def video_fixture(name)
    fixture("media", "video", name)
  end

  def image_fixture(name)
    fixture("media", "images", name)
  end

  def tabular_import_fixture(name)
    fixture("tabular_imports", name)
  end

  def option_set_import_fixture(name)
    fixture("option_set_imports", name)
  end

  def user_import_fixture(name)
    fixture("user_imports", name)
  end

  # Given a File fixture, return args to pass to ActiveStorage attach().
  def attachment_args(fixture)
    {io: fixture, filename: File.basename(fixture)}
  end

  # Accepts a fixture filename and form provided by a spec, and creates xml mimicking odk
  def prepare_odk_fixture(name:, type:, form:, **options)
    items = form.preordered_items.map { |i| ODK::DecoratorFactory.decorate(i) }
    nodes = items.map(&:preordered_option_nodes).uniq.flatten
    option_set_ids = items.map(&:option_set_id).flatten.compact.uniq
    option_sets = find_with_ids_maintaining_order(OptionSet, option_set_ids)
    option_sets = option_sets.map { |os| ODK::DecoratorFactory.decorate(os) }
    xml = prepare_fixture("odk/#{type}s/#{name}.xml",
      formname: [form.name],
      form: [form.id],
      formver: options[:formver].present? ? [options[:formver]] : [form.number],
      itemcode: items.map(&:odk_code),
      itemqcode: items.map(&:code),
      optcode: nodes.map(&:odk_code),
      optsetcode: option_sets.map(&:odk_code),
      questionid: items.map { |i| i.question&.id },
      value: options[:values].presence || [])
    write_fixture_to_file(name: name, type: type, xml: xml) if save_fixtures
    xml
  end

  def write_fixture_to_file(name:, type:, xml:)
    dir = saved_fixture_dir(name: name, type: type)
    path = dir.join("#{name}.xml")
    FileUtils.mkdir_p(dir)
    puts "Saving fixture to #{path}"
    File.open(path, "w") { |f| f.write(xml) }
  end

  def saved_fixture_dir(name:, type:)
    Rails.root.join("tmp/odk/#{type}s/#{name}")
  end

  def find_with_ids_maintaining_order(klass, ids)
    klass.find(ids).index_by(&:id).slice(*ids).values
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

  def in_locale(locale)
    old_locale = I18n.locale
    I18n.locale = locale
    yield
    I18n.locale = old_locale
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
