class UserGroup < ActiveRecord::Base
  include MissionBased

  has_many :user_group_assignments, dependent: :destroy
  has_many :users, through: :user_group_assignments

  scope :by_name, -> { order(:name) }
  scope :name_matching, ->(q) { where("name LIKE ?", "%#{q}%") }
end
