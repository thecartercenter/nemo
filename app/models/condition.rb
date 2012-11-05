class Condition < ActiveRecord::Base
  belongs_to(:questioning, :inverse_of => :condition)
  belongs_to(:ref_qing, :class_name => "Questioning", :foreign_key => "ref_qing_id", :inverse_of => :referring_conditions)
  belongs_to(:option)
  
  before_validation(:clear_blanks)
  before_validation(:clean_times)
  validate(:all_fields_required)
    
  OPS = {
    "is equal to" => {:types => [:decimal, :integer, :text, :long_text, :address, :select_one, :datetime, :date, :time], :code => "="},
    "is less than" => {:types => [:decimal, :integer, :datetime, :date, :time], :code => "<"},
    "is greater than" => {:types => [:decimal, :integer, :datetime, :date, :time], :code => ">"},
    "is less than or equal to" => {:types => [:decimal, :integer, :datetime, :date, :time], :code => "<="},
    "is greater than or equal to" => {:types => [:decimal, :integer, :datetime, :date, :time], :code => "="},
    "is not equal to" => {:types => [:decimal, :integer, :text, :long_text, :address, :select_one, :datetime, :date, :time], :code => "!="},
    "includes" => {:types => [:select_multiple], :code => "="},
    "does not include" => {:types => [:select_multiple], :code => "!="}
  }
  
  def conditionable_qings
    questioning ? questioning.previous_qings.reject{|qing| %w[location].include?(qing.question.type.name)} : []
  end
  
  def question_code_select_options
    conditionable_qings.collect{|qing| ["#{qing.rank}. #{qing.question.code}", qing.id]}
  end
  
  def question_code_type_hash
    Hash[*conditionable_qings.collect{|qing| [qing.id.to_s, qing.question.type.name]}.flatten]
  end
  
  def question_options_hash
    hash = {}
    conditionable_qings.each do |qing| 
      hash[qing.id.to_s] = qing.question.select_options if qing.question.options
    end
    hash
  end
  
  def op_select_options
    ref_question ? 
      OPS.reject{|op, attribs| !attribs[:types].include?(ref_question.type.name.to_sym)}.collect{|op, attribs| [op,op]} :
      []
  end
  
  def option_select_options
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
  
  def to_odk
    # set default lhs
    lhs = "/data/#{ref_question.odk_code}"
    if has_options?
      xpath = "selected(#{lhs}, '#{option_id}')"
      xpath = "not(#{xpath})" if OPS[op][:code] == "!="
    else
      
      # for numeric ref. questions, just convert value to string to get rhs
      if ref_question.type.numeric? 
        rhs = value.to_s
      
      # for temporal ref. questions, need to convert dates to appropriate format
      elsif ref_question.type.temporal?
        # get xpath compatible date type name
        date_type = ref_question.type.name.gsub("datetime", "dateTime")
        format = :"javarosa_#{date_type.downcase}"
        formatted = Time.zone.parse(value).to_s(format)
        lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
        rhs = "'#{formatted}'"
        
      # otherwise just quoted string
      else
        rhs = "'#{value}'"
      end
      
      # build the final xpath expression
      xpath = "#{lhs} #{OPS[op][:code]} #{rhs}"
    end
    xpath
  end
  
  def to_s(lang)
    "Question ##{ref_qing.rank} #{op} \"#{option ? option.name(lang) : value}\""
  end
  
  def to_json
    Hash[[:questioning_id, :ref_qing_id, :op, :value, :option_id].collect{|k| [k, send(k)]}].to_json
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
        qtype = ref_qing.question.type
        
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
      errors.add(:base, "All fields are required.") if ref_qing.blank? || op.blank? || (value.blank? && option_id.blank?)
    end
end
