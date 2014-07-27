class Tagging < ActiveRecord::Base
  belongs_to :question
  belongs_to :tag
  attr_accessible :is_standard, :standard_id
end
