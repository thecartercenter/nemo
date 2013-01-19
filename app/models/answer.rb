class Answer < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  # a flag set by javascript on the client side indicating whether the answer is relevant based on any conditions
  attr_writer(:relevant)

  belongs_to(:questioning, :inverse_of => :answers)
  belongs_to(:option, :inverse_of => :answers)
  belongs_to(:response, :inverse_of => :answers)
  has_many(:choices, :dependent => :destroy, :inverse_of => :answer)
  
  before_validation(:clean_locations)
  before_save(:round_ints)
  before_save(:blanks_to_nulls)
  
  validates(:value, :numericality => true, :if => Proc.new{|a| a.numeric? && !a.value.blank?})
  validate(:min_max)
  validate(:required)

  # creates a new answer from a string from odk
  def self.new_from_str(params)
    str = params.delete(:str)
    ans = new(params)

    # if there was no answer to this question (in the case of a out of sync form) just leave it blank
    return ans if str.nil?

    # set the attributes based on the question type
    if ans.question_type_name == "select_one"
      ans.option_id = str.to_i
    elsif ans.question_type_name == "select_multiple"
      str.split(" ").each{|oid| ans.choices.build(:option_id => oid.to_i)}
    elsif ans.question.type.temporal?
      # parse the string into a time
      val = Time.zone.parse(str)
      
      # convert the parsed time to the appropriate database format unless question is timezone sensitive
      val = val.to_s(:"db_#{ans.question_type_name}") unless ans.question.type.has_timezone?
      
      # assign the value
      ans.send("#{ans.question_type_name}_value=", val)
    else
      ans.value = str
    end
    ans
  end
  
  def choice_for(option)
    choice_hash[option]
  end
  
  def choice_hash(options = {})
    if !@choice_hash || options[:rebuild]
      @choice_hash = {}; choices.each{|c| @choice_hash[c.option] = c}
    end
    @choice_hash
  end
  
  def all_choices
    # for each option, if we have a matching choice, return it and set it's fake bit to true
    # otherwise create one and set its fake bit to false
    options.collect do |o|
      if c = choice_for(o)
        c.checked = true
      else
        c = choices.new(:option => o, :checked => false)
      end
      c
    end
  end
  
  def all_choices=(params)
    # create a bunch of temp objects, discarding any unchecked choices
    submitted = params.values.collect{|p| p[:checked] == '1' ? Choice.new(p) : nil}.compact
    
    # copy new choices into old objects, creating or deleting if necessary
    choices.compare_by_element(submitted, Proc.new{|c| c.option_id}) do |orig, subd|
      # if both exist, do nothing
      # if submitted is nil, destroy the original
      if subd.nil?
        choices.delete(orig)
      # if original is nil, add the new one to this response's array
      elsif orig.nil?
        choices << subd
      end
    end  
  end
  
  def question; questioning ? questioning.question : nil; end
  def rank; questioning.rank; end
  def required?; questioning.required?; end
  def hidden?; questioning.hidden?; end
  def question_name; question.name; end
  def question_hint; question.hint; end
  def question_type_name; question.type.name; end
  def can_have_choices?; question_type_name == "select_multiple"; end
  def location?; question_type_name == "location"; end
  def numeric?; question.type.numeric?; end
  def integer?; question.type.integer?; end
  def options; question.options; end
  
  # relevant defaults to true until set otherwise
  def relevant?
    @relevant.nil? ? true : @relevant
  end
  
  # convert to boolean
  def relevant=(r)
    @relevant = (r == "true")
  end

  # alias
  def relevant; relevant?; end
  
  private
    def required
      if required? && !hidden? && relevant? && !can_have_choices? &&
        value.blank? && time_value.blank? && date_value.blank? && datetime_value.blank? && option_id.nil? 
          errors.add(:base, "This question is required")
      end
    end
    def round_ints
      self.value = value.to_i if integer? && !value.blank?
      return true
    end
    def blanks_to_nulls
      self.value = nil if value.blank?
      return true
    end
    def min_max
      val_f = value.to_f
      if question.maximum && (val_f > question.maximum || question.maxstrictly && val_f == question.maximum) ||
         question.minimum && (val_f < question.minimum || question.minstrictly && val_f == question.minimum)
           errors.add(:base, question.min_max_error_msg)
      end
    end                 
    def clean_locations
      if location? && !value.blank?
        if value.match(configatron.lat_lng_regexp)
          lat = number_with_precision($1.to_f, :precision => 6)
          lng = number_with_precision($3.to_f, :precision => 6)
          self.value = "#{lat} #{lng}"
        else
          self.value = ""
        end
      end
    end
end
