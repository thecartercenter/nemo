class OptionLevel < ActiveRecord::Base
  include MissionBased, Translatable

  attr_accessible :is_standard, :mission_id, :name_translations, :option_set_id, :rank, :standard_id

  belongs_to(:option_set)

  validates(:option_set_id, :presence => true)
  validates(:rank, :presence => true)


  translates :name
end
