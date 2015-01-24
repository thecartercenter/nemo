class Questioning < FormItem
  include Replication::Replicable

  accepts_nested_attributes_for(:question)
  accepts_nested_attributes_for(:condition)

  before_validation(:destroy_condition_if_ref_qing_blank)
  before_create(:set_rank)
  after_destroy(:fix_ranks)

  delegate :name,
           :code,
           :code=,
           :level_count,
           :level,
           :multi_level?,
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
           :all_options,
           :option_path_to_rank_path,
           :rank_path_to_option_path,
           :select_options,
           :odk_code,
           :odk_constraint,
           :subquestions,
           :standardized?,
           :temporal?,
           :numeric?,
           :tags,
           to: :question

  delegate :published?, to: :form
  delegate :smsable?, to: :form, prefix: true
  delegate :verify_ordering, to: :condition, prefix: true, allow_nil: true

  scope(:visible, where(:hidden => false))

  replicable child_assocs: [:question, :condition], backward_assocs: :form, dont_copy: [:hidden, :form_id, :question_id]

  # remove heirarchy of objects
  def self.terminate_sub_relationships(questioning_ids)
    answers = Answer.where(questioning_id: questioning_ids)
    Choice.where(answer_id: answers).delete_all
    answers.delete_all
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

  # gets ranks of all referring conditions' questionings (should use eager loading)
  def referring_condition_ranks
    referring_conditions.map{|c| c.questioning.rank}
  end

  # returns any questionings appearing before this one on the form
  def previous
    form.questionings.reject{|q| !rank.nil? && (q == self || q.rank > rank)}
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

    def destroy_condition_if_ref_qing_blank
      destroy_condition if condition && condition.ref_qing.blank?
    end

    # sets rank if not already set
    def set_rank
      self.rank ||= (form.try(:max_rank) || 0) + 1
      return true
    end

    # repair the ranks of the remaining questions on the form
    def fix_ranks
      form.fix_ranks
    end
end
