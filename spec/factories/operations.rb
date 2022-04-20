# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: operations
#
#  id                                                :uuid             not null, primary key
#  details                                           :string(255)      not null
#  job_class                                         :string(255)      not null
#  job_completed_at                                  :datetime
#  job_error_report                                  :text
#  job_failed_at                                     :datetime
#  job_started_at                                    :datetime
#  notes                                             :string(255)
#  unread                                            :boolean          default(TRUE), not null
#  url                                               :string
#  created_at                                        :datetime         not null
#  updated_at                                        :datetime         not null
#  creator_id                                        :uuid
#  job_id                                            :string(255)
#  mission_id(Operations are possible in admin mode) :uuid
#  provider_job_id                                   :string(255)
#
# Indexes
#
#  index_operations_on_created_at  (created_at)
#  index_operations_on_creator_id  (creator_id)
#  index_operations_on_mission_id  (mission_id)
#
# Foreign Keys
#
#  fk_rails_...                (mission_id => missions.id)
#  operations_creator_id_fkey  (creator_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

FactoryBot.define do
  factory :operation do
    creator factory: :user
    sequence(:details) { |n| "Operation ##{n}" }
    mission { get_mission }
    job_class { TabularImportOperationJob }
  end
end
