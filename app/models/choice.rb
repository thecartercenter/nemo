class Choice < ApplicationRecord
  acts_as_paranoid

  belongs_to :answer, inverse_of: :choices, touch: true
  belongs_to :option, inverse_of: :choices

  delegate :name, to: :option, prefix: true
  delegate :coordinates?, to: :option

  before_save :replicate_location_values

  def checked
    # Only explicitly false should return false.
    # This is so that the default value is true.
    @checked || @checked.nil?
  end
  alias_method :checked?, :checked

  def checked=(value)
    @checked = (value == true || value == '1')
  end

  # We need to override this because of the transient `checked` attribute.
  # Since it's transient and defaults to true, the only way it will have 'changed' is if it's now false.
  def changed?
    !checked? || super
  end

  # This is a temporary method for fetching option_node based on the related OptionSet and Option.
  # Eventually Options will be removed and OptionNodes will be stored on Choices directly.
  def option_node
    OptionNode.where(option_id: option_id, option_set_id: answer.option_set.id).first
  end

  def option_node_id
    option_node.try(:id)
  end

  # This is a temporary method for assigning option based on an OptionNode ID.
  # Eventually Options will be removed and OptionNodes will be stored on Choices directly.
  def option_node_id=(id)
    self.option_id = id.present? ? OptionNode.id_to_option_id(id) : nil
  end

  # This may get called twice during an answer save but who cares.
  def replicate_location_values
    if coordinates?
      self.latitude = option.latitude
      self.longitude = option.longitude
    end
  end
end
