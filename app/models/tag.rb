class Tag < ActiveRecord::Base
  include MissionBased

  belongs_to :mission
  has_many :taggings, dependent: :destroy
  has_many :questions, through: :taggings
  attr_accessible :is_standard, :name, :standard_id
end
