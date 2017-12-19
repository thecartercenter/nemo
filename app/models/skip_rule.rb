class SkipRule < ActiveRecord::Base
  acts_as_list column: :rank, scope: [:source_item_id, deleted_at: nil]

  belongs_to :source_item, class_name: "FormItem", inverse_of: :skip_rules
end
