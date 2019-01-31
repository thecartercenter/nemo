class UserGroupAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :user_group

  validates :user, uniqueness: {scope: :user_group}
  validates :user, :user_group, presence: true
end
