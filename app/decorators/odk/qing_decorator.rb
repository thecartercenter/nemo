# frozen_string_literal: true

module ODK
  # Decorates Questionings for ODK views.
  class QingDecorator < FormItemDecorator
    delegate_all

    def bind_tag(form, subq, xpath_prefix: "/data")
      tag(:bind, nodeset: nodeset(subq, xpath_prefix),
                 type: binding_type_attrib(subq),
                 required: subq.required? ? required_value(form) : nil,
                 readonly: default_answer? && read_only? ? "true()" : nil,
                 relevant: relevance,
                 constraint: constraint,
                 "jr:constraintMsg": constraints? ? jr_constraint_msg : nil,
                 calculate: calculate,
                 "jr:preload": jr_preload,
                 "jr:preloadParams": jr_preload_params)
    end

    def last_saved_setvalue_tag(subq, xpath_prefix: "/data")
      ref = nodeset(subq, xpath_prefix)
      tag(:setvalue, event: "odk-instance-first-load", ref: ref, value: "instance('last-saved')#{ref}")
    end

    def body_tags(xpath_prefix:, group: nil, render_mode: nil)
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

    def constraint_msg(locale)
      msgs = [min_max_error_msg] # Old min/max style, going away later.
      constraints.each do |constraint|
        msgs << if (custom = constraint.rejection_msg(locale, fallbacks: true))
                  custom
                else
                  conditions = ConstraintDecorator.decorate(constraint).human_readable_conditions(nums: false)
                  I18n.t("constraint.odk_message", conditions: conditions)
                end
      end
      msgs.compact.join("; ").presence
    end

    private

    def default_answer?
      default.present? && qtype.defaultable?
    end

    def calculate
      @calculate ||= default_answer? ? ODK::ResponsePatternParser.new(default, src_item: self).to_odk : nil
    end

    def constraint
      exprs = [odk_constraint] # Old min/max style, going away later.
      constraints.each { |c| exprs << "(#{ConditionGroupDecorator.decorate(c.condition_group).to_odk})" }
      exprs.compact.join(" and ").presence
    end

    def nodeset(subq, xpath_prefix)
      [xpath_prefix, subq&.odk_code].compact.join("/")
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

    def jr_constraint_msg
      "jr:itext('#{odk_code}:constraintMsg')"
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
