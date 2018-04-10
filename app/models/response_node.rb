# frozen_string_literal: true

# Parent class for nodes in the answer hierarchy
class ResponseNode < ApplicationRecord
  self.table_name = "answers"

  has_closure_tree(dependent: :destroy)
  # TODO: add ordering using rank? or add ordering column that is populated based on form item rank?
  # TODO: we might want to add touch since the trees aren't very deep
end
