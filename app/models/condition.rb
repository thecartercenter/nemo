class Condition < ActiveRecord::Base
  belongs_to(:questioning)
  belongs_to(:ref_qing, :class_name => "Questioning", :foreign_key => "ref_qing_id")
  belongs_to(:option)
  
  before_validation(:clear_blanks)
  validate(:all_fields_required)
    
  OPS = {
    "is equal to" => {:types => [:decimal, :integer, :text, :long_text, :address, :select_one], :code => "="},
    "is less than" => {:types => [:decimal, :integer], :code => "<"},
    "is greater than" => {:types => [:decimal, :integer], :code => ">"},
    "is less than or equal to" => {:types => [:decimal, :integer], :code => "<="},
    "is greater than or equal to" => {:types => [:decimal, :integer], :code => "="},
    "is not equal to" => {:types => [:decimal, :integer, :text, :long_text, :address, :select_one], :code => "!="},
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
  
  def clone
    self.class.new(:ref_qing_id => ref_qing_id, :op => op, :value => value, :option_id => option_id)
  end
  
  def ref_question
    ref_qing ? ref_qing.question : nil
  end
  
  def verify_ordering
    raise "The new rankings invalidate one or more conditions" if questioning.rank <= ref_qing.rank
  end
  
  def to_odk
    if has_options?
      xpath = "selected(/data/#{ref_question.code}, '#{option_id}')"
      xpath = "not(#{xpath})" if OPS[op][:code] == "!="
    else
      val_str = ref_question.type.numeric? ? value.to_s : "'#{value}'"
      xpath = "/data/#{ref_question.code} #{OPS[op][:code]} #{val_str}"
    end
    xpath
  end
  
  private 
    def clear_blanks
      begin
        self.value = nil if value.blank?
        self.option_id = nil if option_id.blank?
      rescue
      end
    end
    def all_fields_required
      errors.add(:base, "All fields are required.") if ref_qing.blank? || op.blank? || (value.blank? && option_id.blank?)
    end
end
