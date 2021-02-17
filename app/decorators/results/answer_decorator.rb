# frozen_string_literal: true

module Results
  class AnswerDecorator < ResponseNodeDecorator
    def classes
      ["answer", "form-field", "qtype-#{qtype_name.dasherize}", mode_class, error_class].compact.join(" ")
    end

    def hint
      question_hint = questioning.hint&.chomp(".")&.concat(".")
      drop_hint = h.t("response.drop_hint.#{qtype.name}", default: "",
                                                          max_size_mib: Cnfg.max_upload_size_mib).presence
      [question_hint, drop_hint].join(" ")
    end

    def shortened
      case qtype_name
      when "select_one"
        option_name
      when "select_multiple"
        choices.map(&:option_name).join(", ")
      when "datetime", "date"
        casted_value.present? ? h.l(casted_value) : nil
      when "time"
        time_value.present? ? h.l(time_value, format: :time_only) : nil
      when "decimal"
        value.present? ? format("%.2f", value.to_f) : nil
      when "text", "long_text", "barcode"
        h.truncate(h.sanitize(value), length: 32, escape: false)
      when "integer", "counter", "location"
        value
      end
    end

    # Returns a collection for use in the select_multiple form, which is always single level.
    # For each option, if we have a matching choice, just return it (checked? defaults to true)
    # otherwise create one and set checked? to false.
    def all_choices
      choices_by_option_node = choices.select(&:checked?).index_by(&:option_node)
      option_set.first_level_option_nodes.map do |node|
        choices_by_option_node[node] || choices.build(option_node: node, checked: false)
      end
    end

    # Returns an array of hashes of form {latitude: x, longitude: y} for the answer (select one, location)
    # or any choices with coordinates (select multiple).
    def latlngs
      case qtype_name
      when "select_one", "location"
        [{latitude: latitude, longitude: longitude}]
      when "select_multiple"
        choices.select(&:coordinates?).map { |c| {latitude: c.latitude, longitude: c.longitude} }
      else
        []
      end
    end
  end
end
