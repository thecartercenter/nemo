# frozen_string_literal: true

# Models a restriction on valid answers, similar to a Rails validation, but for NEMO forms.
class Constraint < ApplicationRecord
  include MissionBased
  include Translatable

  translates :rejection_msg

  # Constraint ranks are currently not editable, but they provide a source of deterministic ordering
  # which is useful in tests and in UI consistency.
  acts_as_list column: :rank, scope: [:questioning_id]

  belongs_to :questioning
end
