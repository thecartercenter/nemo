# Implements the policy about when a form's version should be upgraded.
# Any form component objects (Option, OptionSet, OptionNode, Question, Questioning) should call this class after updating.
# It will tell the appropriate Forms to upgrade their versions.
class FormVersioningPolicy
  # Sets the upgrade_neccessary flag on forms where necessary.
  def notify(obj, action)
    forms_needing_upgrade(obj, action).each do |f|
      f.reload
      raise "standard forms should not be subject to version policy" if f.standardizable? && f.is_standard?
      f.flag_for_upgrade!
    end
  end

  private

  # Returns a list of forms needing upgrade based on the given object and action.
  # If the list is empty, it means that no form's version will have to be updated.
  def forms_needing_upgrade(obj, action)
    case obj.class.name
    when "Option"
      case action
      when :destroy
        # changing an option is fine, but destroying an option is a trigger
        return obj.forms
      end

    when "OptionSet"
      case action
      when :update
        # changing the option order is a trigger if the form is smsable
        return obj.forms.select(&:smsable?) if obj.ranks_changed?
      end

    when "OptionNode"
      # If option_set is nil, it means the option set is just getting created, so no need to go any further.
      return [] if obj.option_set.nil?

      case action
      when :create
        # adding an option to an option set is a trigger for smsable forms
        return obj.option_set.forms.select(&:smsable?)
      when :destroy
        # Removing an option from an option set is always trigger.
        return obj.option_set.forms
      end

    when "Questioning"
      case action
      when :create
        # creating a new required question is a trigger
        return [obj.form] if obj.required?
      when :update
        # if required is changed, it's a trigger
        # changing question rank is a trigger if form is smsable
        # changing question visibility is a trigger if changed to visible (not hidden)
        return [obj.form] if obj.required_changed? || obj.rank_changed? && obj.form.smsable? || obj.hidden_changed? && !obj.hidden?
      end

    when "Condition"
      case action
      when :create
        # creating a condition is a trigger if question is required
        return [obj.form] if obj.questioning.required?
      when :update
        # changing condition is a trigger if question is required
        return [obj.form] if obj.changed? && obj.questioning.required?
      when :destroy
        # destroying a condition is a trigger if question is required
        return [obj.form] if obj.questioning.required?
      end

    when "Question"
      case action
      when :update
        # changing question type, option set, or constraints is a trigger
        return obj.forms if obj.qtype_name_changed? || obj.option_set_id_changed? || obj.constraint_changed?
      end
    end

    return []
  end
end