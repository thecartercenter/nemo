# frozen_string_literal: true

module Results
  # Generates cached JSON for a given response.
  class ResponseJsonGenerator
    include ActionView::Helpers::TextHelper

    attr_accessor :response

    BASE_URL_PLACEHOLDER = "__NEMO_HOST__"

    def initialize(response)
      self.response = response
    end

    def as_json
      json = {}
      in_locale(response.mission.default_locale) do
        add_metadata(json)
        root = response.root_node_including_tree(
          :choices, form_item: :question, option_node: %i[option_set option]
        )
        add_answers(root, json) unless root.nil?
        add_nil_answers(response.form, json)
      end
      json
    end

    private

    delegate :form, :user, to: :response

    def in_locale(locale)
      original_locale = I18n.locale
      I18n.locale = locale
      yield
      I18n.locale = original_locale
    end

    def add_metadata(json)
      json["ResponseID"] = response.id
      json["ResponseShortcode"] = response.shortcode
      json["FormName"] = form.name
      json["ResponseSubmitterName"] = user.name
      json["ResponseSubmitDate"] = response.created_at.iso8601
      json["ResponseReviewed"] = response.reviewed?
      json["LastCached"] = Time.zone.now.iso8601
    end

    # Adds data for the given Response node to the given json object.
    # Object may be an array or hash.
    def add_answers(response_node, json)
      response_node.children.each do |child_node|
        if child_node.is_a?(Answer)
          json[child_node.question_code] = value_for(child_node)
        elsif child_node.is_a?(AnswerSet)
          json[child_node.question_code] = answer_set_value(child_node)
        elsif child_node.is_a?(AnswerGroup)
          add_group_answers(child_node, json)
        elsif child_node.is_a?(AnswerGroupSet)
          set = json[node_key(child_node)] = []
          add_answers(child_node, set)
        end
      end
    end

    def add_group_answers(group, json)
      if group.repeatable?
        json << (item = {})
        add_answers(group, item)
      else
        subgroup = json[node_key(group)] = {}
        add_answers(group, subgroup)
      end
    end

    # Make sure we include everything specified by metadata in our output,
    # even if an older Response didn't include that qing/group originally.
    def add_nil_answers(form_item, json)
      # Note: This logic is similar to add_answers, but with Form instead of Response.
      # The logic seems more readable when they're independent like this.
      # It also preserves old data better.
      form_item.children.map do |child_item|
        if child_item.is_a?(QingGroup)
          add_nil_group_answers(child_item, json)
        else
          is_collection = OData::QuestionType.odata_type_for(child_item.question.qtype_name).is_a?(Array)
          json[node_key(child_item)] ||= is_collection ? [] : nil
        end
      end
    end

    def add_nil_group_answers(group, json)
      if group.repeatable?
        entries = json[node_key(group)] ||= []
        # Make sure it's an array of hashes, not a hash (in case 'repeatable' changed).
        entries = json[node_key(group)] = [entries] unless entries.is_a?(Array)
        entries.each { |entry| add_nil_answers(group, entry) }
      else
        subgroup = json[node_key(group)] ||= {}
        # Make sure it's a hash, not an array of hashes (in case 'repeatable' changed).
        subgroup = json[node_key(group)] = subgroup.first if subgroup.is_a?(Array)
        add_nil_answers(group, subgroup)
      end
    end

    def answer_set_value(answer_set)
      set = {}
      answer_set.children.each do |answer|
        option_node = answer.option_node
        set[option_node.level_name] = answer.option_name if option_node
      end
      ENV["NEMO_USE_DATA_FACTORY"].present? ? set.to_s : set
    end

    def value_for(answer)
      return media_value(answer) if answer.multimedia?
      case answer.qtype_name
      when "date" then answer.date_value
      when "time" then answer.time_value&.to_s(:std_time)
      when "datetime" then answer.datetime_value&.iso8601
      when "integer", "counter" then answer.value&.to_i
      when "decimal" then answer.value&.to_f
      when "select_one" then answer.option_name
      when "select_multiple" then select_multiple_value(answer)
      when "location" then location_value(answer)
      else format_value(answer.value)
      end
    end

    def select_multiple_value(answer)
      value = answer.choices.empty? ? [] : answer.choices.map(&:option_name).sort
      ENV["NEMO_USE_DATA_FACTORY"].present? ? value.to_s : value
    end

    def media_value(answer)
      item = answer.media_object.item
      return nil unless item.attached?
      path = Rails.application.routes.url_helpers.rails_blob_url(item, disposition: "attachment",
                                                                       only_path: true)
      "#{BASE_URL_PLACEHOLDER}#{path}"
    end

    def location_value(answer)
      value = Answer::LOCATION_COLS.map do |key|
        [key.titleize, answer.attributes[key]&.to_f]
      end.to_h
      ENV["NEMO_USE_DATA_FACTORY"].present? ? value.to_s : value
    end

    def format_value(value)
      # Data that's been copied from MS Word contains a bunch of HTML decoration.
      # Get rid of that via simple_format.
      /\A<!--/.match?(value) ? simple_format(value) : value.to_s
    end

    # Returns the OData key for a given group, response node, or form node.
    def node_key(node)
      node.code.vanilla
    end
  end
end
