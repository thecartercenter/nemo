class SkipRule < ActiveRecord::Base
  acts_as_list column: :rank, scope: [:source_item_id, deleted_at: nil]
end
