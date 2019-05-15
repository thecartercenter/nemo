# == Schema Information
#
# Table name: choices
#
#  id         :uuid             not null, primary key
#  latitude   :decimal(8, 6)
#  longitude  :decimal(9, 6)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  answer_id  :uuid             not null
#  option_id  :uuid             not null
#
# Indexes
#
#  index_choices_on_answer_id                (answer_id)
#  index_choices_on_answer_id_and_option_id  (answer_id,option_id) UNIQUE
#  index_choices_on_option_id                (option_id)
#
# Foreign Keys
#
#  choices_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#  choices_option_id_fkey  (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#

class Choice < ApplicationRecord
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
