class Questioning < ActiveRecord::Base
  include FormVersionable

  belongs_to(:form, :inverse_of => :questionings, :counter_cache => true)
  belongs_to(:question, :autosave => true, :inverse_of => :questionings)
  has_many(:answers, :dependent => :destroy, :inverse_of => :questioning)
  has_one(:condition, :autosave => true, :dependent => :destroy, :inverse_of => :questioning)
  has_many(:referring_conditions, :class_name => "Condition", :foreign_key => "ref_qing_id", :dependent => :destroy, :inverse_of => :ref_qing)
  
  before_validation(:destroy_condition_if_ref_qing_blank)
  before_create(:set_rank)

  # also validates the associated condition because condition has validates(:questioning, ...)
  
  accepts_nested_attributes_for(:question)
  accepts_nested_attributes_for(:condition)
  
  delegate :code, :code=, :option_set, :option_set=, :option_set_id, :option_set_id=, :qtype_name, :qtype_name=, :qtype, 
    :has_options?, :options, :select_options, :odk_code, :odk_constraint, :to => :question
  delegate :published?, :to => :form
  delegate :verify_ordering, :to => :condition, :prefix => true, :allow_nil => true

  # clones and returns a set of questionings, including their conditions
  # assumes qings are in order in which they appear on the form
  # does not save qings and conditions, just initializes them
  # does NOT set form_id since the expectation is that these will be used on a new form
  def self.duplicate(qings)
    # create basic clones and store cleverly
    qid_hash = {}; new_qings = []
    qings.each do |qing|
      # create the basic clone
      new_qing = new(:question_id => qing.question_id, :rank => qing.rank, :required => qing.required, :hidden => qing.hidden)
      
      # store in the hash (in case it's needed during condition cloning for later qings)
      qid_hash[qing.question_id] = new_qing
      
      # clone the condition if necessary
      new_qing.condition = qing.condition.duplicate if qing.condition
      
      # store in the array
      new_qings << new_qing
    end
    
    # return the cloned qings
    new_qings
  end

  # returns any questionings appearing before this one on the form
  def previous
    form.questionings.reject{|q| !rank.nil? && (q == self || q.rank > rank)}
  end

  def has_condition?
    !condition.nil?
  end

  # REFACTOR: should use translation delegation, from abandoned std_objs branch
  def method_missing(*args)
    # pass appropriate methods on to question
    if is_question_method?(args[0].to_s)
      question.send(*args)
    else
      super
    end
  end
 
  def respond_to?(symbol, *)
    is_question_method?(symbol.to_s) || super
  end
 
  def respond_to_missing?(symbol, include_private)
    is_question_method?(symbol.to_s) || super
  end
  
  def is_question_method?(symbol)
    symbol.match(/^((name|hint)_([a-z]{2})(=?))(_before_type_cast)?$/)
  end
  # /REFACTOR
  
  private
    # sets rank if not already set
    def set_rank
      self.rank ||= (form.try(:max_rank) || 0) + 1
      return true
    end

    def destroy_condition_if_ref_qing_blank
      condition.destroy if condition && condition.ref_qing.blank?
    end
end
