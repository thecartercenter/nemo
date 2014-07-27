class Tag < ActiveRecord::Base
  belongs_to :mission
  attr_accessible :is_standard, :name, :standard_id
end
