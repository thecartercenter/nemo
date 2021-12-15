# frozen_string_literal: true

module ODK
  # Decorates forms for ODK views.
  class FormDecorator < BaseDecorator
    delegate_all

    # XML tag names for the two incomplete response questions
    IR_QUESTION = "ir01"
    IR_CODE = "ir02"

    def default_response_name_instance_tag
      if default_response_name.present?
        content_tag(:meta, tag(:instanceName))
      else
        ""
      end
    end

    def default_response_name_bind_tag
      if default_response_name.present?
        calculate = ODK::ResponsePatternParser.new(default_response_name, src_item: root_group).to_odk
        tag(:bind, nodeset: "/data/meta/instanceName",
                   calculate: calculate,
                   readonly: "true()",
                   type: "string")
      else
        ""
      end
    end

    # Binding for the question that asks if there are any incomplete responses.
    def ir_question_binding
      tag("bind",
        nodeset: "/data/#{IR_QUESTION}",
        required: "true()",
        type: "select1")
    end

    # Binding for the question that prompts for the override code.
    def ir_code_binding
      tag("bind",
        nodeset: "/data/#{IR_CODE}",
        required: "true()",
        relevant: "/data/#{IR_QUESTION} = 'yes'",
        constraint: ". = '#{override_code}'",
        type: "string")
    end

    # Whether this form needs an accompanying manifest for odk.
    def needs_manifest?
      needs_external_csv? || enabled_questionings.any?(&:media_prompt?)
    end

    def needs_external_csv?
      enabled_questionings.any? { |q| decorate(q).select_one_with_external_csv? }
    end

    def needs_last_saved_instance?
      enabled_questionings.any?(&:preload_last_saved?)
    end

    # returns array of option sets that are referenced by the default dynamic calculation
    def referenced_option_sets(qing)
      codes = qing.default.scan(ODK::DynamicPatternParser::CODE_ONLY_REGEX)
      mission = qing.mission
      questions = codes.flatten.map { |c| Question.find_by(mission_id: mission.id, code: c) }.compact
      questions.map(&:option_set).compact
    end

    # returns array of option sets needed for dynamic calculations
    def option_sets_for_instances
      opt_sets = enabled_questionings.map do |qing|
        if qing.default.present? && qing.default =~ ODK::DynamicPatternParser::VALUE_REGEX
          referenced_option_sets(qing)
        end
      end
      opt_sets.flatten.compact.uniq
    end
  end
end
