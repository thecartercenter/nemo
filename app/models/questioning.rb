class Questioning < FormItem
  include Replication::Replicable

  accepts_nested_attributes_for(:question)
  accepts_nested_attributes_for(:condition)

  before_validation(:destroy_condition_if_ref_qing_blank)

  delegate :name,
    :code,
    :code=,
    :level_count,
    :level,
    :multilevel?,
    :option_set,
    :option_set=,
    :option_set_id,
    :option_set_id=,
    :printable?,
    :qtype_name,
    :qtype_name=,
    :qtype,
    :has_options?,
    :options,
    :first_level_option_nodes,
    :all_options,
    :first_leaf_option,
    :first_leaf_option_node,
    :select_options,
    :odk_code,
    :odk_constraint,
    :subquestions,
    :standardized?,
    :temporal?,
    :multimedia?,
    :numeric?,
    :tags,
    :sms_formatting_as_text?,
    :sms_formatting_as_appendix?,
    :preordered_option_nodes,
    to: :question


  delegate :published?, to: :form
  delegate :smsable?, to: :form, prefix: true
  delegate :ref_qing_full_dotted_rank, :ref_qing_id, to: :condition, prefix: true, allow_nil: true
  delegate :repeatable?, :group_name, to: :parent, prefix: true, allow_nil: true

  scope(:visible, -> { where(hidden: false) })

  replicable child_assocs: [:question, :condition], backward_assocs: :form, dont_copy: [:hidden, :form_id, :question_id]

  # remove heirarchy of objects
  def self.terminate_sub_relationships(questioning_ids)
    answers = Answer.where(questioning_id: questioning_ids)
    Choice.where(answer_id: answers).delete_all
    answers.destroy_all
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

  def condition_changed?
    condition.try(:changed?)
  end

  # Gets full dotted ranks of all referring conditions' questionings.
  def referring_condition_ranks
    referring_conditions.map { |c| c.questioning.full_dotted_rank }
  end

  # Returns any questionings appearing before this one on the form.
  # For an unsaved questioning, returns all questions on form.
  # If an unsaved question does not have a form defined, this will result in an error.
  def previous
    return form.questionings if new_record?
    form.questionings.reject { |q| q == self || (q.full_rank <=> full_rank) == 1 }
  end

  # Returns smsable forms
  def smsable?
    !hidden? && question.qtype.smsable?
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
    symbol.match(/\A((name|hint)_([a-z]{2})(=?))(_before_type_cast)?\z/)
  end

  # /REFACTOR
  def inspect
    id
  end

  private

  def destroy_condition_if_ref_qing_blank
    destroy_condition if condition && condition.ref_qing.blank?
  end

end
