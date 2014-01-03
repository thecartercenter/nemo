class OptionLevel < ActiveRecord::Base
  include MissionBased, Translatable

  # TODO make sure this gets deleted on mission delete

  attr_accessible :is_standard, :mission_id, :name_translations, :option_set_id, :rank, :standard_id

  belongs_to(:option_set)

  validates(:option_set_id, :presence => true)
  validates(:rank, :presence => true)
  validate(:not_all_blank_name_translations)

  translates :name



  private

    # checks that at least one name translation is not blank
    def not_all_blank_name_translations
      errors.add(:base, :names_cant_be_all_blank) if name_all_blank?
    end
end
