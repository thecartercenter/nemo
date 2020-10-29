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

require "rails_helper"

describe Constraint do
  it "has a valid factory" do
    create(:constraint)
  end

  describe "validation" do
    describe "condition presence" do
      context "with no conditions" do
        subject(:constraint) { build(:constraint, no_conditions: true) }
        it { is_expected.to have_errors(conditions: "There must be at least one condition.") }
      end
    end
  end
end
