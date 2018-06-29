# frozen_string_literal: true

# Implements the policy about when a form's version should be upgraded.
# Any form component objects (Option, OptionSet, OptionNode, Question, Questioning)
# should call this class after updating.
# It will tell the appropriate Forms to upgrade their versions.
#
# The goal of this policy is to provide some granularity over when downloading a new form is required.
# If we add a non-required question to the end of a form, it might not be necessary for everyone to
# re-download the form, for instance. If we add a required question, on the other hand, it is.
class FormVersioningPolicy
  # Sets the upgrade_neccessary flag on forms where necessary.
  def notify(obj, action)
    forms_needing_upgrade(obj, action).reject(&:is_standard?).each do |f|
      f.reload
      f.flag_for_upgrade!
    end
  end

  private

  # Returns a list of forms needing upgrade based on the given object and action.
  # If the list is empty, it means that no form's version will have to be updated.
  def forms_needing_upgrade(obj, action)
    return [] if obj.saved_change_to_attribute?(:id) && action == :update # This is a create, not an update

    case obj.class.name
    when "Option"
      case action
      when :destroy
        # Changing an option is fine, but destroying an option is a trigger
        return obj.forms
      end

    when "OptionSet"
      case action
      when :update
        # Changing the option order is a trigger if the form is smsable
        return obj.forms.select(&:smsable?) if obj.ranks_changed? || obj.saved_change_to_attribute?(:sms_guide_formatting)
      end

    when "OptionNode"
      # If option_set is nil, it means the option set is just getting created, so no need to go any further.
      return [] if obj.option_set.nil?

      case action
      when :create
        # Adding an option to an option set is a trigger for smsable forms
        return obj.option_set.forms.select(&:smsable?)
      when :destroy
        # Removing an option from an option set is always trigger.
        return obj.option_set.forms
      end

    when "Questioning"
      case action
      when :create
        # Creating a new required question is a trigger
        return [obj.form] if obj.required?
      when :update
        # If required is changed, it's a trigger
        # Changing question rank is a trigger if form is smsable
        # Changing question visibility is a trigger if changed to visible (not hidden)
        if obj.saved_change_to_attribute?(:required) || (obj.saved_change_to_attribute?(:rank) && obj.form.smsable?) ||
            (obj.saved_change_to_attribute?(:hidden) && !obj.hidden?)
          return [obj.form]
        end
      when :destroy
        # If form smsable and the questioning was NOT the last one on the form, it's a trigger.
        if obj.form.smsable? && obj.form.last_qing.present? && obj.rank <= obj.form.last_qing.rank
          return [obj.form]
        end
      end

    when "Condition"
      # Conditions on SkipRules and QingGroups need to be treated separately here.
      # For now this is just for Conditions on Questionings.
      return [] unless obj.conditionable.is_a?(Questioning)
      case action
      when :create
        # Creating a condition is not a trigger even if question is required because person submitting
        # old form would still think question is required, which does not lead to loss of data.
        return []
      when :update
        # Changing condition is a trigger if question is required because person submitting old form
        # might skip a required question based on an outdated condition. This wouldn't cause an error, but
        # may lead to undesired data.
        return [obj.form] if obj.changed? && obj.conditionable.required?
      when :destroy
        # Destroying a condition is a trigger if question is required because person submitting old form
        # wouldn't know about lack of condition and might try to omit now-required information.
        return [obj.form] if obj.conditionable.required?
      end

    when "Question"
      case action
      when :update
        # Changing question type, option set, constraints
        return obj.forms if obj.saved_change_to_attribute?(:qtype_name) || obj.saved_change_to_attribute?(:option_set_id) ||
            obj.saved_change_to_attribute?(:constraint)
      end
    end

    []
  end
end
