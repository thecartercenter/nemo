# frozen_string_literal: true

module Forms
  # Computes display conditions that are implied from SkipRules.
  class ConditionComputer
    attr_accessor :form, :preordered_form_items, :table, :active_rules, :last_item_cache

    def initialize(form)
      self.form = form
      self.preordered_form_items = form.preordered_items(
        eager_load: [:display_conditions, {skip_rules: :conditions}]
      )
    end

    def condition_group_for(item)
      build_table if table.nil?
      table[item] || empty_root_group
    end

    private

    def build_table
      self.table = {}
      self.active_rules = []
      self.last_item_cache = {}
      preordered_form_items.each do |item|
        add_display_conditions(item)
        deactivate_rules_if_at_dest_item(item)
        process_active_rules_for_item(item)
        activate_rules_from_item(item)
      end
    end

    def add_display_conditions(item)
      add_to_table(item, item.condition_group) if item.display_conditionally?
    end

    def deactivate_rules_if_at_dest_item(item)
      active_rules.reject! { |r| r.dest_item == item }
    end

    # Scans through the active rules and adds them to the table for the given item when appropriate.
    def process_active_rules_for_item(item)
      active_rules.each do |rule|
        # We don't apply skip rules to hidden items because they’re usually auto-populated.
        # For example, metadata questions are automatically hidden and we don't want to skip those.
        next if item.disabled?
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
      table[item] ||= empty_root_group
      table[item].members << update_conditionables(condition_group, item)
      last_item_cache[condition_group] = item
    end

    # In the database, the members' (uncomputed) conditions have their conditionable as the skip rule.
    # When displaying in the view, computed conditions have the current form item as their conditionable.
    # We make copies to avoid incorrect data elsewhere
    def update_conditionables(condition_group, item)
      new_group = condition_group.dup
      new_group.members = condition_group.members.map do |condition|
        new_condition = condition.dup
        new_condition.conditionable = item
        new_condition
      end
      new_group
    end

    def empty_root_group
      ConditionGroup.new(name: "Root")
    end
  end
end
