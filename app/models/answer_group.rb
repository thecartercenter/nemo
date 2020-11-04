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

# Corresponds with a QingGroup
# An AnswerGroups's parent is an AnswerGroupSet or an AnswerGroup.
# Its children can be Answers, AnswerSets, AnswerGroups, or AnswerGroupSets.
class AnswerGroup < ResponseNode
  alias qing_group form_item
  delegate :group_name, :group_hint, to: :form_item

  def repeatable?
    parent.is_a?(AnswerGroupSet)
  end
end
