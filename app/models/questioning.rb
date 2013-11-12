class Questioning < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable

  belongs_to(:form, :inverse_of => :questionings, :counter_cache => true)
  belongs_to(:question, :autosave => true, :inverse_of => :questionings)
  has_many(:answers, :dependent => :destroy, :inverse_of => :questioning)
  has_one(:condition, :autosave => true, :dependent => :destroy, :inverse_of => :questioning)
  has_many(:referring_conditions, :class_name => "Condition", :foreign_key => "ref_qing_id", :dependent => :destroy, :inverse_of => :ref_qing)

  before_validation(:destroy_condition_if_ref_qing_blank)
  before_create(:set_rank)
  before_create(:set_mission)
  after_destroy(:fix_ranks)

  # also validates the associated condition because condition has validates(:questioning, ...)

  accepts_nested_attributes_for(:question)
  accepts_nested_attributes_for(:condition)

  delegate :name, :code, :code=, :option_set, :option_set=, :option_set_id, :option_set_id=, :qtype_name, :qtype_name=, :qtype,
    :has_options?, :options, :select_options, :odk_code, :odk_constraint, :to => :question
  delegate :published?, :to => :form
  delegate :smsable?, :to => :form, :prefix => true
  delegate :verify_ordering, :to => :condition, :prefix => true, :allow_nil => true

  replicable :child_assocs => [:question, :condition], :parent_assoc => :form

  scope(:visible, where(:hidden => false))

  # returns any questionings appearing before this one on the form
  def previous
    form.questionings.reject{|q| !rank.nil? && (q == self || q.rank > rank)}
  end

  def has_condition?
    !condition.nil?
  end

  # checks if this form has any answers
  # uses the form.qing_answer_count method because these requests tend to come in batches so better
  # to fetch the counts for all qings on the form at once
  def has_answers?
    form.qing_answer_count(self) > 0
  end

  # destroys condition and ensures that the condition param is nulled out
  def destroy_condition
    condition.destroy
    self.condition = nil
  end

  # checks if any of the core fields (condition, required, hidden) have changed
  def core_changed?
    condition.try(:changed?) || required_changed? || hidden_changed?
  end

  # gets ranks of all referring conditions' questionings (should use eager loading)
  def referring_condition_ranks
    referring_conditions.map{|c| c.questioning.rank}
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

  # Remove Heirarch of Objects
  def self.terminate_sub_relationships(questionings)
     answers = Answer.where(questioning_id: questionings)
     Choice.where(answer_id: answers).delete_all
     answers.delete_all
  end

  private
    # sets rank if not already set
    def set_rank
      self.rank ||= (form.try(:max_rank) || 0) + 1
      return true
    end

    def destroy_condition_if_ref_qing_blank
      destroy_condition if condition && condition.ref_qing.blank?
    end

    # copy mission from question
    def set_mission
      self.mission = form.try(:mission)
    end

    # repair the ranks of the remaining questions on the form
    def fix_ranks
      form.fix_ranks
    end
end
