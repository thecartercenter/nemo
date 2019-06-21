# frozen_string_literal: true

class ConditionDecorator < ApplicationDecorator
  delegate_all

  # Generates a human readable representation of condition.
  # include_code - Includes the question code in the string.
  #   May not always be desireable e.g. with printable forms.
  def human_readable(**opts)
    if left_qing_id.blank?
      "" # need to return something here to avoid nil errors
    else
      bits = []
      bits.concat(qing_name_and_code(left_qing, **opts))
      bits.concat(right_side_is_literal? ? right_side_literal_bits(**opts) : right_side_qing_bits(**opts))
      bits.join(" ")
    end
  end

  private

  def right_side_literal_bits(**_opts)
    bits = []
    if left_qing_has_options?
      bits << option_node.level_name if left_qing.multilevel?
      target = option_node.option_name
    else
      target = value
    end
    bits << I18n.t("condition.operators.human_readable.#{op}")
    bits << (numeric_ref_question? ? target : "\"#{target}\"")
    bits
  end

  def right_side_qing_bits(**opts)
    bits = []
    bits << I18n.t("condition.operators.human_readable.#{op}")
    bits.concat(qing_name_and_code(right_qing, **opts))
    bits
  end

  def qing_name_and_code(qing, include_code: false)
    [Question.model_name.human, "##{qing.full_dotted_rank}", ("[#{qing.code}]" if include_code)].compact
  end
end
