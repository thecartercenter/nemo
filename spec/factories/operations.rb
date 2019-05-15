# == Schema Information
#
# Table name: operations
#
#  id                                                :uuid             not null, primary key
#  attachment_content_type                           :string
#  attachment_download_name                          :string
#  attachment_file_name                              :string
#  attachment_file_size                              :integer
#  attachment_updated_at                             :datetime
#  details                                           :string(255)      not null
#  job_class                                         :string(255)      not null
#  job_completed_at                                  :datetime
#  job_error_report                                  :text
#  job_failed_at                                     :datetime
#  job_started_at                                    :datetime
#  unread                                            :boolean          default(TRUE), not null
#  url                                               :string
#  created_at                                        :datetime         not null
#  updated_at                                        :datetime         not null
#  creator_id                                        :uuid             not null
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

FactoryGirl.define do
  factory :operation do
    creator factory: :user
    sequence(:details) { |n| "Operation ##{n}" }
    mission { get_mission }
    job_class TabularImportOperationJob
  end
end
