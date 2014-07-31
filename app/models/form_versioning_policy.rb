# Implements the policy about when a form's version should be upgraded.
# Any form component objects (Option, OptionSet, OptionNode, Question, Questioning) should call this class before updating.
# This class tells them which, if any, forms will require a version update as a result.
# If the update proceeds, this class should be notified again, whereupon it will tell the appropriate Forms to upgrade their versions.
class FormVersioningPolicy
  # returns a list of triggers that performing the given option on the given object will result in
  # if the list is empty, it means that no form's version will have to be updated
  def self.check(obj, action)
    triggers = []

    case obj.class.name

    when "Option"
      case action
      when :destroy
        # changing an option is fine, but destroying an option is a trigger
        triggers << {:reason => :destroyed_option, :forms => obj.forms}
      end

    when "OptionSet"
      case action
      when :update
        # changing the option order is a trigger if the form is smsable
        triggers << {:reason => :option_order_changed, :forms => obj.forms.select{|f| f.smsable?}} if obj.ranks_changed?
      end

    when "Optioning"
      case action
      when :create
        # adding an option to an option set is a trigger for smsable forms
        triggers << {:reason => :option_added_to_set, :forms => obj.option_set.forms.select{|f| f.smsable?}}
      when :update
        # changing optioning parent is a trigger for smsable forms
        if obj.parent_id_changed?
          triggers << {:reason => :option_parent_changed, :forms => obj.option_set.forms.select{|f| f.smsable?}}
        end
      when :destroy
        # removing an option from an option set is a trigger
        triggers << {:reason => :option_removed_from_set, :forms => obj.option_set.forms}
      end

    when "Questioning"
      case action
      when :create
        # creating a new required question is a trigger
        triggers << {:reason => :new_required_question, :forms => [obj.form]} if obj.required?
      when :update
        # if required is changed, it's a trigger
        triggers << {:reason => :question_required_changed, :forms => [obj.form]} if obj.required_changed?

        # changing question rank is a trigger if form is smsable
        triggers << {:reason => :question_rank_changed, :forms => [obj.form]} if obj.rank_changed? && obj.form.smsable?

        # changing question visibility is a trigger if changed to visible (not hidden)
        triggers << {:reason => :question_hidden_changed, :forms => [obj.form]} if obj.hidden_changed? && !obj.hidden?
      end

    when "Condition"
      case action
      when :create
        # creating a condition is a trigger if question is required
        triggers << {:reason => :new_condition, :forms => [obj.form]} if obj.questioning.required?
      when :update
        # changing condition is a trigger if question is required
        triggers << {:reason => :condition_changed, :forms => [obj.form]} if obj.changed? && obj.questioning.required?
      when :destroy
        # destroying a condition is a trigger if question is required
        triggers << {:reason => :condition_destroyed, :forms => [obj.form]} if obj.questioning.required?
      end

    when "Question"
      case action
      when :update
        # changing question type, option set, or constraints is a trigger
        triggers << {:reason => :question_type_changed, :forms => obj.forms} if obj.qtype_name_changed?
        triggers << {:reason => :question_option_set_changed, :forms => obj.forms} if obj.option_set_id_changed?
        triggers << {:reason => :question_constraint_changed, :forms => obj.forms} if obj.constraint_changed?
      end
    end
    return triggers
  end

  # this method is called when the change actually occurs. it sets the upgrade_neccessary flag on forms where necessary.
  def self.notify(obj, action)
    # get the list of forms that need to be upgraded
    forms_to_upgrade = check(obj, action).collect{|trigger| trigger[:forms]}.flatten.uniq

    # reload all forms to ensure consistency, especially for testing
    forms_to_upgrade.each(&:reload)

    # flag them
    forms_to_upgrade.each do |f|
      raise "standard forms should not be subject to version policy" if f.is_standard?
      f.flag_for_upgrade!
    end
  end
end