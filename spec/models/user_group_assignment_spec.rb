# frozen_string_literal: true

# rubocop:disable Layout/LineLength
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
#  user_group_assignments_user_group_id_fkey  (user_group_id => user_groups.id) ON DELETE => restrict ON UPDATE => restrict
#  user_group_assignments_user_id_fkey        (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe UserGroupAssignment do
  it "has a valid factory" do
    user_group_assignment = create(:user_group_assignment)
    expect(user_group_assignment).to be_valid
  end
end
