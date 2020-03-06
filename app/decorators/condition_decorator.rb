# frozen_string_literal: true

class ConditionDecorator < ApplicationDecorator
  delegate_all

  # Generates a human readable representation of condition.
  # codes - Includes the question code in the string.
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
      target = option_node.name
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
    bits.concat(qing_name_and_code(right_qing, **opts.merge(sentence_start: false)))
    bits
  end

  def qing_name_and_code(qing, codes: false, nums: true, sentence_start: true)
    bits = []
    if conditionable.base_item == qing
      this_q = I18n.t("condition.this_question")
      this_q.downcase! unless sentence_start
      bits << this_q
    else
      bits << Question.model_name.human << "##{qing.full_dotted_rank}" if nums
      bits << "[#{qing.code}]" if codes
    end
    bits
  end
end
