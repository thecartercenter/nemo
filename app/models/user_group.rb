class UserGroup < ApplicationRecord
  include MissionBased

  has_many :user_group_assignments, dependent: :destroy
  has_many :users, through: :user_group_assignments
  has_many :broadcast_addressings, inverse_of: :addressee, foreign_key: :addressee_id, dependent: :destroy
  has_many :form_forwardings, inverse_of: :recipient, foreign_key: :recipient_id, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :mission_id }

  scope :by_name, -> { order(:name) }
  scope :name_matching, ->(q) { where("name LIKE ?", "%#{q}%") }

  # remove heirarchy of objects
  def self.terminate_sub_relationships(group_ids)
    UserGroupAssignment.where(user_group_id: group_ids).delete_all
  end
end
