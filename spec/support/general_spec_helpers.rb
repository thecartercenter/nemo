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

  # `substitutions` should be a hash of arrays.
  # For each hash pair, e.g. `grp: groups`, the method substitutes
  # e.g. `__grp_8__` in the file with `groups[7]`.
  def prepare_expectation(filename, substitutions)
    expectation_file(filename).tap do |contents|
      substitutions.each do |key, values|
        values.each_with_index do |value, i|
          contents.gsub!("*#{key}#{i + 1}*", value.to_s)
        end
      end
      puts contents
    end
  end

  def prepare_odk_expectation(filename, form)
    items = form.preordered_items
    nodes = items.map { |item| item.preordered_option_nodes }.uniq.flatten
    puts items.each_with_index.map { |n,i| "#{n.odk_code} => #{i + 1} (#{n.rank})" }.join("\n")
    puts nodes.each_with_index.map { |n,i| "#{n.odk_code} => #{i + 1} (#{n.option.name})" }.join("\n")
    prepare_expectation("odk/#{filename}",
      form: [form.id],
      formver: [form.code],
      itemcode: items.map(&:odk_code),
      optcode: nodes.map(&:odk_code)
    )
  end

  def in_timezone(tz)
    old_tz = Time.zone
    Time.zone = tz
    yield
    Time.zone = old_tz
  end
end
