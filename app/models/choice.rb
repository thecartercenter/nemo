# frozen_string_literal: true

# rubocop:disable Layout/LineLength
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
#  option_node_id :uuid
#
# Indexes
#
#  index_choices_on_answer_id       (answer_id)
#  index_choices_on_option_node_id  (option_node_id)
#
# Foreign Keys
#
#  choices_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...            (option_node_id => option_nodes.id)
#
# rubocop:enable Layout/LineLength

class Choice < ApplicationRecord
  belongs_to :answer, inverse_of: :choices, touch: true
  belongs_to :option_node, inverse_of: :choices

  before_save :replicate_location_values

  attr_writer :mission_id

  def option_name
    option_node&.name
  end

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

  # This may get called twice during an answer save but who cares.
  def replicate_location_values
    return unless option_node.coordinates?
    self.latitude = option_node.latitude
    self.longitude = option_node.longitude
  end
end
