module Standardizable
  extend ActiveSupport::Concern

  included do
    # create self-associations in both directions for is-copy-of relationship
    belongs_to(:standard, :class_name => name)
    has_many(:copies, :class_name => name, :foreign_key => 'standard_id')
  end
end