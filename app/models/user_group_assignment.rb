class UserGroupAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :user_group

  validates :user, uniqueness: {scope: %i[user_group deleted_at]}
  validates :user, :user_group, presence: true
end
