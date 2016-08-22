class UserGroup < ActiveRecord::Base
  include MissionBased

  has_many :user_group_assignments, dependent: :destroy
  has_many :users, through: :user_group_assignments
  has_many :broadcast_addressings, inverse_of: :addressee, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :mission_id }

  scope :by_name, -> { order(:name) }
  scope :name_matching, ->(q) { where("name LIKE ?", "%#{q}%") }
end
