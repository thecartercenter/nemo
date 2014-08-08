class Tagging < ActiveRecord::Base
  include MissionBased

  belongs_to :question
  belongs_to :tag
  attr_accessible :is_standard, :standard_id
end
