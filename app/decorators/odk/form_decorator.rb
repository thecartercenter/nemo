# frozen_string_literal: true

module Odk
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
        calculate = Odk::ResponsePatternParser.new(default_response_name, src_item: root_group).to_odk
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
        relevant: "selected(/data/#{IR_QUESTION}, 'yes')",
        constraint: ". = '#{override_code}'",
        type: "string")
    end

    # Whether this form needs an accompanying manifest for odk.
    def needs_manifest?
      # For now this is IFF there are any multilevel option sets or questions with audio prompts
      visible_questionings.any? { |q| q.multilevel? || q.audio_prompt.exists? }
    end
  end
end
