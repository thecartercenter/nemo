class SkipRule < ActiveRecord::Base
  acts_as_list column: :rank, scope: [:source_item_id, deleted_at: nil]

  belongs_to :source_item, class_name: "FormItem", inverse_of: :skip_rules
  belongs_to :dest_item, class_name: "FormItem"
  has_many :conditions, -> { by_ref_qing_rank }, as: :conditionable, dependent: :destroy

  before_validation :set_foreign_key_on_conditions

  validate :require_dest_item

  accepts_nested_attributes_for :conditions, allow_destroy: true, reject_if: :all_blank

  def all_fields_blank?
    destination.blank? && dest_item.blank? && conditions.all?(&:all_fields_blank?)
  end

  private

  # Since conditionable is polymorphic, inverse is not available and we have to do this explicitly
  def set_foreign_key_on_conditions
    conditions.each { |c| c.conditionable = self}
  end

  def require_dest_item
    if destination != "end" && dest_item.nil?
      errors.add(:dest_item_id, :blank_unless_goto_end)
    end
  end
end
