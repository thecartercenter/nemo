class Condition < ActiveRecord::Base
  belongs_to(:questioning, :inverse_of => :condition)
  belongs_to(:ref_qing, :class_name => "Questioning", :foreign_key => "ref_qing_id", :inverse_of => :referring_conditions)
  belongs_to(:option, :dependent => :destroy)
  
  before_validation(:clear_blanks)
  before_validation(:clean_times)
  validate(:all_fields_required)
    
  OPS = [
    {:name => :eq, :types => [:decimal, :integer, :text, :long_text, :address, :select_one, :datetime, :date, :time], :code => "="},
    {:name => :lt, :types => [:decimal, :integer, :datetime, :date, :time], :code => "<"},
    {:name => :gt, :types => [:decimal, :integer, :datetime, :date, :time], :code => ">"},
    {:name => :leq, :types => [:decimal, :integer, :datetime, :date, :time], :code => "<="},
    {:name => :geq, :types => [:decimal, :integer, :datetime, :date, :time], :code => "="},
    {:name => :neq, :types => [:decimal, :integer, :text, :long_text, :address, :select_one, :datetime, :date, :time], :code => "!="},
    {:name => :inc, :types => [:select_multiple], :code => "="},
    {:name => :ninc, :types => [:select_multiple], :code => "!="}
  ]
  
  # all questionings that can be referred to by this condition
  def refable_qings
    questioning ? questioning.previous_qings.reject{|qing| %w[location].include?(qing.question.qtype.name)} : []
  end
  
  # returns a hash mapping ids for conditionable questionings to their types
  def refable_qing_types
    Hash[*refable_qings.map{|qing| [qing.id, qing.question.qtype.name]}.flatten]
  end
  
  # returns a hash mapping qing IDs to arrays of options (for select questions only), for use when choosing an option for the condition.
  def refable_qing_option_lists
    Hash[*refable_qings.reject{|qing| !qing.question.options}.map{|qing| [qing.id, qing.question.select_options]}.flatten(1)]
  end

  # returns names of all operators that are applicable to this condition based on its referred question
  def applicable_operator_names
    ref_question ? OPS.reject{|o| !o[:types].include?(ref_question.qtype.name.to_sym)}.map{|o| o[:name]} : []
  end
  
  def ref_question_select_options
    ref_question ? ref_question.select_options : []
  end
  
  def has_options?
    ref_question && !ref_question.options.nil?
  end
  
  def duplicate(new_qing, qid_hash)
    # look up the new ref_qing_id
    new_ref_qing = qid_hash[ref_qing.question_id]
    # initialize and return
    new_qing.build_condition(:ref_qing => new_ref_qing, :op => op, :value => value, :option_id => option_id)
  end
  
  def ref_question
    ref_qing ? ref_qing.question : nil
  end
  
  def verify_ordering
    raise ConditionOrderingError.new if questioning.rank <= ref_qing.rank
  end
  
  # gets the hash from the OPS array corresponding to this conditions operator
  def operator
    @operator ||= OPS.index_by{|o| o[:name]}[op.to_sym]
  end
  
  # returns all known operators
  def operators
    OPS
  end
  
  def to_odk
    # set default lhs
    lhs = "/data/#{ref_question.odk_code}"
    if has_options?
      xpath = "selected(#{lhs}, '#{option_id}')"
      xpath = "not(#{xpath})" if operator[:name] == :neq
    else
      
      # for numeric ref. questions, just convert value to string to get rhs
      if ref_question.qtype.numeric? 
        rhs = value.to_s
      
      # for temporal ref. questions, need to convert dates to appropriate format
      elsif ref_question.qtype.temporal?
        # get xpath compatible date type name
        date_type = ref_question.qtype.name.gsub("datetime", "dateTime")
        format = :"javarosa_#{date_type.downcase}"
        formatted = Time.zone.parse(value).to_s(format)
        lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
        rhs = "'#{formatted}'"
        
      # otherwise just quoted string
      else
        rhs = "'#{value}'"
      end
      
      # build the final xpath expression
      xpath = "#{lhs} #{operator[:code]} #{rhs}"
    end
    xpath
  end
  
  def to_s
    words = I18n.t(op, :scope => [:condition, :operators])
    "#{Question.model_name.human} ##{ref_qing.rank} #{words} \"#{option ? option.name : value}\""
  end
  
  # if options[:dropdown_values] is included, adds a series of lists of values for use with form dropdowns
  def as_json(options = {})
    fields = %w(questioning_id ref_qing_id op value option_id)
    fields += %w(refable_qing_types refable_qing_option_lists operators) if options[:dropdown_values]
    Hash[*fields.map{|k| [k, send(k)]}.flatten(1)]
  end
  
  private 
    def clear_blanks
      begin
        self.value = nil if value.blank?
        self.option_id = nil if option_id.blank?
      rescue
      end
      return true
    end
    
    # parses and reformats time strings given as conditions
    def clean_times
      if ref_qing && !value.blank?
        # get the question type
        qtype = ref_qing.question.qtype
        
        begin
          # reformat only if it's a temporal question
          self.value = Time.zone.parse(value).to_s(:"std_#{qtype.name}") if qtype.temporal? 
        rescue
          # reset to nil if error in parsing
          # catch additional error incase frozen hash
          (self.value = nil) rescue nil
        end
      end
      return true
    end
    
    def all_fields_required
      errors.add(:base, :all_required) if ref_qing.blank? || op.blank? || (value.blank? && option_id.blank?)
    end
end
