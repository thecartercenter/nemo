# frozen_string_literal: true

# Decorates Questionings for rendering outside ODK. There is a separate Questioning decorator for ODK.
class QuestioningDecorator < FormItemDecorator
  def concatenated_conditions
    concatenator = display_if == "all_met" ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map(&:human_readable).join(" #{concatenator} ")
  end

  # Unique, sorted list of questionings to which this question actually refers,
  # whether by display logic or skip logic.
  def refd_qings
    @refd_qings ||= (super + skip_rules.flat_map(&:refd_qings) + constraints.flat_map(&:refd_qings))
      .uniq.sort_by(&:full_rank)
  end

  # Sorted, unique list of full dotted ranks or the word "End"
  # representing targets of skip rules on this questioning.
  def skip_rule_targets
    targets = skip_rules.map { |r| r.dest_item || :end }.uniq
    targets.sort_by! { |t| t == :end ? [1e9] : t.full_rank }
    targets.map { |t| t == :end ? h.t("skip_rule.end") : "##{t.full_dotted_rank}" }
  end

  def name_and_rank
    str = safe_str << "#{full_dotted_rank}. "
    str << h.reqd_sym if required?
    str << (name.presence || code)
  end

  def selection_instructions
    content = "#{I18n.t("question_type.#{qtype_name}")}:"
    str = h.content_tag(:strong, content)
    str << h.tag(:br)
  end

  private

  def decorated_conditions
    ConditionDecorator.decorate_collection(display_conditions)
  end
end
