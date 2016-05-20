class UserGroup < ActiveRecord::Base
  include MissionBased

  has_many :users, through: :user_group_assignments
end
