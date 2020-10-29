# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: constraints
#
#  id                         :uuid             not null, primary key
#  accept_if                  :string(16)       default("all_met"), not null
#  rank                       :integer          not null
#  rejection_msg_translations :jsonb
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  mission_id                 :uuid
#  source_item_id             :uuid             not null
#
# Indexes
#
#  index_constraints_on_mission_id               (mission_id)
#  index_constraints_on_source_item_id           (source_item_id)
#  index_constraints_on_source_item_id_and_rank  (source_item_id,rank) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#  fk_rails_...  (source_item_id => form_items.id)
#
# rubocop:enable Layout/LineLength

# Models a restriction on valid answers, similar to a Rails validation, but for NEMO forms.
class Constraint < ApplicationRecord
  include FormLogical
  include Translatable

  translates :rejection_msg

  validates :conditions, presence: true

  replicable child_assocs: [:conditions], backward_assocs: [:source_item]

  def condition_group
    @condition_group ||= Forms::ConditionGroup.new(
      true_if: accept_if,
      members: conditions,
      name: "Constraint for #{source_item.code}"
    )
  end
end
