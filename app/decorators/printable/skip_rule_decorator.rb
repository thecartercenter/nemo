module Printable
  class SkipRuleDecorator < ApplicationDecorator
    delegate_all
    # Generates a human readable representation of a skip rule.

    def human_readable(prefs = {})
      "Skip to Question #{QingDecorator.new(dest_item).name_and_rank} if #{decorate_conditions}"
    end

    def decorate_conditions
      decorated_conditions = ConditionDecorator.decorate_collection(condition_group.members)
      concatenator = (condition_group.true_if == "all_met") ? I18n.t("common.AND") : I18n.t("common.OR")
      decorated_conditions.map{ |c| c.human_readable}.join(" #{concatenator} ")
    end
  end
end