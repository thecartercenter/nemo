# frozen_string_literal: true

module Results
  # Generates cached JSON for a given response.
  class ResponseJsonGenerator
    attr_accessor :response

    def initialize(response)
      self.response = response
    end

    def as_json
      object = {}
      object["ResponseID"] = response.id
      object["ResponseShortcode"] = response.shortcode
      object["FormName"] = form.name
      object["ResponseSubmitterName"] = user.name
      object["ResponseSubmitDate"] = response.created_at.iso8601
      object["ResponseReviewed"] = response.reviewed?
      root = response.root_node_including_tree(:choices, form_item: :question, option_node: :option_set)
      add_answers(root, object)
      object
    end

    private

    delegate :form, :user, to: :response

    def add_answers(node, object)
      node.children.each do |child_node|
        if child_node.is_a?(Answer)
          object[child_node.question_code] = value_for(child_node)
        elsif child_node.is_a?(AnswerSet)
          object[child_node.question_code] = answer_set_value(child_node)
        elsif child_node.is_a?(AnswerGroup) && !child_node.repeatable?
          add_answers(child_node, object)
        end
      end
    end

    def answer_set_value(answer_set)
      set = {}
      answer_set.children.each do |answer|
        option_node = answer.option_node
        set[option_node.level_name] = answer.option_name
      end
      set
    end

    def value_for(answer)
      case answer.qtype_name
      when "date" then answer.date_value
      when "time" then answer.time_value.to_s(:std_time)
      when "datetime" then answer.datetime_value.iso8601
      when "integer", "counter" then answer.value&.to_i
      when "decimal" then answer.value&.to_f
      when "select_one" then answer.option_name
      when "select_multiple" then answer.choices.empty? ? nil : answer.choices.map(&:option_name).sort
      when "location" then answer.attributes.slice(*%w[latitude longitude altitude accuracy])
      else answer.value.presence
      end
    end
  end
end
