# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
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
#  option_id         :uuid
#  parent_id         :uuid
#  questioning_id    :uuid             not null
#  response_id       :uuid             not null
#
# Indexes
#
#  index_answers_on_new_rank        (new_rank)
#  index_answers_on_option_id       (option_id)
#  index_answers_on_parent_id       (parent_id)
#  index_answers_on_questioning_id  (questioning_id)
#  index_answers_on_response_id     (response_id)
#  index_answers_on_type            (type)
#
# Foreign Keys
#
#  answers_option_id_fkey       (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#  answers_questioning_id_fkey  (questioning_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#  answers_response_id_fkey     (response_id => responses.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

# Corresponds with a Repeat Qing Group
# An AnswerGroupSet's parent is an AnswerGroup.
# Its children are AnswerGroups.
class AnswerGroupSet < ResponseNode
  alias qing_group form_item

  def name
    qing_group.group_name
  end
end
