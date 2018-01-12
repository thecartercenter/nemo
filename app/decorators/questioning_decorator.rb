class QuestioningDecorator < ApplicationDecorator
  delegate_all

  def concatenated_conditions
    concatenator = (display_if == "all_met") ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map{ |c| c.human_readable}.join(" #{concatenator} ")
  end

  # Unique, sorted list of questionings to which this question actually refers,
  # whether by display logic or skip logic.
  def refd_qings
    return @refd_qings if defined?(@refd_qings)
    qings = display_conditions.map(&:ref_qing) + skip_rules.flat_map(&:ref_qings)
    @refd_qings = qings.uniq.sort_by(&:full_rank)
  end

  # Sorted, unique list of full dotted ranks or the word "End"
  # representing targets of skip rules on this questioning.
  def skip_rule_targets
    targets = skip_rules.map { |r| r.dest_item || :end }.uniq
    targets.sort_by! { |t| t == :end ? [1e9] : t.full_rank }
    targets.map { |t| t == :end ? h.t("skip_rule.end") : "##{t.full_dotted_rank}" }
  end

  private

  def decorated_conditions
    ConditionDecorator.decorate_collection(display_conditions)
  end
end
