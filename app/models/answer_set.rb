# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: answers
#
#  id                :uuid             not null, primary key
#  accuracy          :decimal(9, 3)
#  altitude          :decimal(9, 3)
#  date_value        :date
#  datetime_value    :datetime
#  latitude          :decimal(8, 6)
#  longitude         :decimal(9, 6)
#  new_rank          :integer          default(0), not null
#  old_inst_num      :integer          default(1), not null
#  old_rank          :integer          default(1), not null
#  pending_file_name :string
#  time_value        :time
#  tsv               :tsvector
#  type              :string           default("Answer"), not null
#  value             :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :uuid             not null
#  option_node_id    :uuid
#  parent_id         :uuid
#  questioning_id    :uuid             not null
#  response_id       :uuid             not null
#
# Indexes
#
#  index_answers_on_mission_id      (mission_id)
#  index_answers_on_new_rank        (new_rank)
#  index_answers_on_option_node_id  (option_node_id)
#  index_answers_on_parent_id       (parent_id)
#  index_answers_on_questioning_id  (questioning_id)
#  index_answers_on_response_id     (response_id)
#  index_answers_on_type            (type)
#
# Foreign Keys
#
#  answers_questioning_id_fkey  (questioning_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#  answers_response_id_fkey     (response_id => responses.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...                 (mission_id => missions.id)
#  fk_rails_...                 (option_node_id => option_nodes.id)
#
# rubocop:enable Layout/LineLength

# Corresponds with a multilevel questioning. An AnswerSet's parent is an AnswerGroup. Its children are Answers
class AnswerSet < ResponseNode
  alias questioning form_item
  alias answers children

  delegate :option_set, to: :questioning

  def option_node_path
    OptionNodePath.new(
      option_set: questioning.option_set,
      target_node: lowest_non_nil_answer.try(:option_node)
    )
  end

  def invalid?
    answers.any?(&:invalid?)
  end

  def question_code
    questioning.code
  end

  private

  # Returns the non-nil answer with the lowest rank. May return nil if the set is blank.
  def lowest_non_nil_answer
    answers.reverse.find(&:present?)
  end
end
