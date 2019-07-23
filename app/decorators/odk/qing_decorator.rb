# frozen_string_literal: true

module Odk
  # Decorates Questionings for ODK views.
  class QingDecorator < FormItemDecorator
    delegate_all

    def bind_tag(form, subq, xpath_prefix: "/data")
      tag(:bind, nodeset: [xpath_prefix, subq.try(:odk_code)].compact.join("/"),
                 type: binding_type_attrib(subq),
                 required: required? && visible? && subq.first_rank? ? required_value(form) : nil,
                 readonly: default_answer? && read_only? ? "true()" : nil,
                 relevant: relevance,
                 constraint: constraint,
                 "jr:constraintMsg": constraint_msg,
                 calculate: calculate,
                 "jr:preload": jr_preload,
                 "jr:preloadParams": jr_preload_params)
    end

    def body_tags(group: nil, render_mode: nil, xpath_prefix:)
      return safe_str unless visible?
      render_mode ||= :normal

      # Note that subqings here refers to multiple levels of a cascading select question, not groups.
      # If group is a multilevel_fragment, we are supposed to just render one of the subqings here.
      # This is so they can be wrapped with the appropriate group headers/hint and such.
      subqing_subset = group&.multilevel_fragment? ? [subqings[group.level - 1]] : subqings

      subqing_subset.map do |sq|
        sq.input_tag(render_mode: render_mode, xpath_prefix: xpath_prefix)
      end.reduce(:<<)
    end

    def subqings
      decorate_collection(object.subqings, context: context)
    end

    def decorated_option_set
      @decorated_option_set ||= decorate(option_set)
    end

    def select_one_with_external_csv?
      qtype_name == "select_one" && decorated_option_set.external_csv?
    end

    # Whether this question is either visible or has some important behind the scenes thing like
    # preload or calculate. Ideally hidden questions and disabled questions would be different things
    # and we'd render the former but not the latter, but this is what it is for now.
    def renderable?
      visible? || jr_preload || calculate
    end

    private

    def default_answer?
      default.present? && qtype.defaultable?
    end

    def calculate
      @calculate ||= default_answer? ? Odk::ResponsePatternParser.new(default, src_item: self).to_odk : nil
    end

    def constraint
      exprs = [odk_constraint] # Old min/max style, going away later.
      constraints.each { |c| exprs << "(#{ConditionGroupDecorator.decorate(c.condition_group).to_odk})" }
      exprs.compact.join(" and ").presence
    end

    def constraint_msg
      msgs = [min_max_error_msg] # Old min/max style, going away later.
      constraints.each do |constraint|
        msgs << ConstraintDecorator.decorate(constraint).human_readable_conditions(nums: false)
      end
      str = msgs.compact.join("; ").presence
      return nil if str.nil?
      I18n.t("constraint.odk_message", conditions: str)
    end

    def jr_preload
      @jr_preload ||=
        case metadata_type
        when "formstart", "formend" then "timestamp"
        end
    end

    def jr_preload_params
      @jr_preload_params ||=
        case metadata_type
        when "formstart" then "start"
        when "formend" then "end"
        end
    end

    # If a question is required, then determine the appropriate value
    # based on whether the form allows incomplete responses.
    def required_value(form)
      # If form allows incompletes, question is required only if
      # the answer to 'are there missing answers' is 'no'.
      form.allow_incomplete? ? "/data/#{FormDecorator::IR_QUESTION} = 'no'" : "true()"
    end

    def binding_type_attrib(subq)
      # When using external CSV method, ODK wants non-first-level selects to have type 'string'.
      select_one_with_external_csv? && !subq.first_rank? ? "string" : odk_name
    end
  end
end
