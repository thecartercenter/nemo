module Odk
  class QingDecorator < FormItemDecorator
    delegate_all

    def bind_tag(form, subq, group: nil, xpath_prefix: "/data")
      tag(:bind,
        nodeset: [xpath_prefix, subq.try(:odk_code)].compact.join("/"),
        type: binding_type_attrib(subq),
        required: required? && visible? && subq.first_rank? ? required_value(form) : nil,
        readonly: has_default? && read_only? ? "true()" : nil,
        relevant: relevance,
        constraint: subq.odk_constraint,
        "jr:constraintMsg": subq.min_max_error_msg,
        calculate: calculate,
        "jr:preload": jr_preload,
        "jr:preloadParams": jr_preload_params
      )
    end

    def subqings
      decorate_collection(object.subqings, context: context)
    end

    private

    def has_default?
      default.present? && qtype.defaultable?
    end

    def calculate
      has_default? ? Odk::ResponsePatternParser.new(default, src_item: self).to_odk : nil
    end

    def jr_preload
      case metadata_type
      when "formstart", "formend" then "timestamp"
      else nil
      end
    end

    def jr_preload_params
      case metadata_type
      when "formstart" then "start"
      when "formend" then "end"
      else nil
      end
    end

    # If a question is required, then determine the appropriate value
    # based on whether the form allows incomplete responses.
    def required_value(form)
      # If form allows incompletes, question is required only if
      # the answer to 'are there missing answers' is 'no'.
      form.allow_incomplete? ? "selected(/data/#{FormDecorator::IR_QUESTION}, 'no')" : "true()"
    end

    def binding_type_attrib(subq)
      # ODK wants non-first-level selects to have type 'string'.
      subq.first_rank? ? subq.odk_name : "string"
    end
  end
end
