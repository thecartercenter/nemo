class SkipRule < ActiveRecord::Base
  acts_as_list column: :rank, scope: [:source_item_id, deleted_at: nil]

  belongs_to :source_item, class_name: "FormItem", inverse_of: :skip_rules
  has_many :conditions, -> { by_ref_qing_rank }, as: :conditionable, dependent: :destroy

  before_validation :set_foreign_key_on_conditions

  accepts_nested_attributes_for :conditions, allow_destroy: true, reject_if: :all_blank

  private

  # Since conditionable is polymorphic, inverse is not available and we have to do this explicitly
  def set_foreign_key_on_conditions
    conditions.each { |c| c.conditionable = self}
  end
end
