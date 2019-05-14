# frozen_string_literal: true

# Models a restriction on valid answers, similar to a Rails validation, but for NEMO forms.
class Constraint < ApplicationRecord
  belongs_to :mission
  belongs_to :questioning
end
