class Tagging < ActiveRecord::Base
  include MissionBased, Replicable, Standardizable

  belongs_to :question
  belongs_to :tag
  attr_accessible :is_standard, :standard_id

  replicable parent_assoc: :question
end
