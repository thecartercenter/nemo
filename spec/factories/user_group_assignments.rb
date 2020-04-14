# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: user_group_assignments
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_group_id :uuid             not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_user_group_assignments_on_user_group_id              (user_group_id)
#  index_user_group_assignments_on_user_id                    (user_id)
#  index_user_group_assignments_on_user_id_and_user_group_id  (user_id,user_group_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_group_id => user_groups.id)
#  fk_rails_...  (user_id => users.id)
#
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :user_group_assignment do
    user
    user_group
  end
end
