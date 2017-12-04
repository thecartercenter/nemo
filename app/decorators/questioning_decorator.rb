class QuestioningDecorator < ApplicationDecorator
  delegate_all

  def conditions_instructions
    concatenator = (display_if == "all_met") ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map{ |c| c.human_readable}.join(" #{concatenator} ")
  end

  private

  def decorated_conditions
    ConditionDecorator.decorate_collection(display_conditions)
  end
end
