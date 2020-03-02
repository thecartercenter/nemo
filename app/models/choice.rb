# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: choices
#
#  id             :uuid             not null, primary key
#  latitude       :decimal(8, 6)
#  longitude      :decimal(9, 6)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  answer_id      :uuid             not null
#  option_id      :uuid             not null
#  option_node_id :uuid
#
# Indexes
#
#  index_choices_on_answer_id                (answer_id)
#  index_choices_on_answer_id_and_option_id  (answer_id,option_id) UNIQUE
#  index_choices_on_option_id                (option_id)
#  index_choices_on_option_node_id           (option_node_id)
#
# Foreign Keys
#
#  choices_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#  choices_option_id_fkey  (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...            (option_node_id => option_nodes.id)
#
# rubocop:enable Metrics/LineLength

class Choice < ApplicationRecord
  belongs_to :answer, inverse_of: :choices, touch: true
  belongs_to :option, inverse_of: :choices
  belongs_to :option_node, inverse_of: :choices

  delegate :option_name, to: :option_node

  before_save :replicate_location_values

  attr_writer :mission_id

  def checked
    # Only explicitly false should return false.
    # This is so that the default value is true.
    @checked || @checked.nil?
  end
  alias checked? checked

  def checked=(value)
    @checked = (value == true || value == "1")
  end

  # We need to override this because of the transient `checked` attribute.
  # Since it's transient and defaults to true, the only way it will have 'changed' is if it's now false.
  def changed?
    !checked? || super
  end

  def coordinates?
    latitude.present? && longitude.present?
  end

  def option=(option)
    self[:option_node_id] = OptionNode.find_by(option_id: option.id, option_set_id: answer.option_set_id)&.id
    super
  end

  def option_id=(id)
    self[:option_node_id] = OptionNode.find_by(option_id: id, option_set_id: answer.option_set_id)&.id
    super
  end

  def option_node=(node)
    self[:option_id] = node.option_id # Temporary until we get rid of option_id column.
    super
  end

  def option_node_id=(id)
    if id.present?
      node = OptionNode.find(id)
      self[:option_id] = node.option_id # Temporary until we get rid of option_id column.
    end
    super
  end

  # This may get called twice during an answer save but who cares.
  def replicate_location_values
    return unless option_node.coordinates?
    self.latitude = option_node.latitude
    self.longitude = option_node.longitude
  end
end
