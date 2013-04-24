# Implements the policy about when a form's version should be upgraded.
# Any form component objects (Option, OptionSet, OptionSetting, Question, Questioning) should call this class before updating.
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
        # changing the option order is a trigger
        triggers << {:reason => :option_order_changed, :forms => obj.forms} if obj.ordering_changed?
      end
      
    when "OptionSetting"
      case action
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
        
        # changing question rank is a trigger
        triggers << {:reason => :question_rank_changed, :forms => [obj.form]} if obj.rank_changed?
      end

    when "Question"
      case action
      when :update
        # changing question type is a trigger
        triggers << {:reason => :question_type_changed, :forms => obj.forms} if obj.question_type_id_changed?
      end
    end
    return triggers
  end
  
  # this method is called when the change actually occurs. it sets the upgrade_neccessary flag on forms where necessary.
  def self.notify(obj, action)
    # get the list of forms that need to be upgraded
    forms_to_upgrade = check(obj, action).collect{|trigger| trigger[:forms]}.flatten.uniq
    
    # flag them
    forms_to_upgrade.each{|f| f.flag_for_upgrade!}
  end
end