class OptionLevel < ActiveRecord::Base
  include MissionBased, Translatable

  attr_accessible :is_standard, :mission, :mission_id, :name_translations, :option_set_id, :rank, :standard_id, :name, :option_set

  belongs_to(:option_set)
  has_many(:optionings, :inverse_of => :option_level)
  has_many(:subquestions, :inverse_of => :option_level, :dependent => :destroy)

  # we validate against option_set and not option_set_id so that validation won't fail on create
  validates(:option_set, :presence => true)

  validates(:rank, :presence => true)
  validate(:not_all_blank_name_translations)

  translates :name



  private

    # checks that at least one name translation is not blank
    def not_all_blank_name_translations
      errors.add(:base, :names_cant_be_all_blank) if name_all_blank?
    end
end
