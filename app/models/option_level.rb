# frozen_string_literal: true

# Represents the name of one level of an option set (e.g. 'Country', 'State', or 'City')
class OptionLevel
  include ActiveModel::Model
  include Translatable

  MAX_NAME_LENGTH = 20

  attr_accessor :option_set

  translates :name

  # Required by Translatable
  delegate :mission_id, to: :option_set

  # For serialization.
  def attributes
    %w[name name_translations].map_hash { |a| send(a) }
  end

  def as_json(_options = {})
    super(root: false)
  end
end
