# Computes display conditions that are implied from SkipRules.
module Forms
  class ConditionComputer
    attr_accessor :form, :form_items, :table, :active_rules, :last_item_cache

    def initialize(form)
      self.form = form
      self.form_items = form.preordered_items(eager_load: [:display_conditions, skip_rules: :conditions])
    end

    def condition_group_for(item)
      table[item] || empty_group
    end

    def build_table
      self.table = {}
      self.active_rules = []
      self.last_item_cache = {}
      form_items.each do |item|
        add_display_conditions(item)
        deactivate_rules_if_at_dest_item(item)
        process_active_rules_for_item(item)
        activate_rules_from_item(item)
      end
    end

    private

    def add_display_conditions(item)
      add_to_table(item, item.condition_group) if item.display_conditionally?
    end

    def deactivate_rules_if_at_dest_item(item)
      active_rules.reject! { |r| r.dest_item == item }
    end

    # Scans through the active rules and adds them to the table for the given item when appropriate.
    def process_active_rules_for_item(item)
      active_rules.each do |rule|
        next if item.descendants.include?(rule.dest_item)
        next if item_has_been_added_to_ancestor?(rule.condition_group, item)
        add_to_table(item, rule.condition_group)
      end
    end

    # Adds skip rules from the current item to the active list.
    def activate_rules_from_item(item)
      active_rules.concat(item.skip_rules)
    end

    # Checks if a ConditionGroup has been added to the table for an ancestor of the given item.
    def item_has_been_added_to_ancestor?(condition_group, item)
      # Since we are doing a preorder traversal, we know that if the ConditionGroup has been added
      # to an ancestor, it must have been the last item it was added to.
      last_item = last_item_cache[condition_group]
      last_item && item.ancestors.include?(last_item)
    end

    def add_to_table(item, condition_group)
      table[item] ||= empty_group
      table[item].members << condition_group
      last_item_cache[condition_group] = item
    end

    def empty_group
      ConditionGroup.new
    end
  end
end
