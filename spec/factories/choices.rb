# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: choices
#
#  id             :uuid             not null, primary key
#  latitude       :decimal(8, 6)
#  longitude      :decimal(9, 6)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  answer_id      :uuid             not null
#  option_node_id :uuid
#
# Indexes
#
#  index_choices_on_answer_id       (answer_id)
#  index_choices_on_option_node_id  (option_node_id)
#
# Foreign Keys
#
#  choices_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...            (option_node_id => option_nodes.id)
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :choice do
  end
end
