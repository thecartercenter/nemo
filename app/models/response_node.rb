# frozen_string_literal: true

# Parent class for nodes in the answer hierarchy
class ResponseNode < ApplicationRecord
  self.table_name = "answers"

  has_closure_tree(dependent: :destroy, order: :rank)
end
