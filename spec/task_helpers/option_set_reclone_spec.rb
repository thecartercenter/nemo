# frozen_string_literal: true

require "rails_helper"

describe TaskHelpers::OptionSetReclone do
  let!(:orig) { create(:option_set, option_names: :multilevel) }
  let!(:clone) { orig.replicate(mode: :clone) }
  let!(:form) { create(:form, question_types: %w[select_one integer]) }
  subject(:recloner) { described_class.new }

  before do
    # This index now prevents the situation we're fixing here from ever happening.
    # So we need to disable it while we test this thing.
    # It will be restored when the transaction is rolled back by DatabaseCleaner
    ActiveRecord::Base.connection.execute("DROP INDEX index_option_sets_on_root_node_id")

    clone.update_column(:root_node_id, orig.root_node_id)

    # Clear out the option nodes that wouldn't have been there before this bug was fixed.
    OptionNode.where(option_set: clone).delete_all

    # Make the condition on the form point to the cloned option set.
    form.c[0].question.update!(option_set: clone)
    form.c[1].display_conditions.create!(left_qing: form.c[0], op: "eq", option_node: clone.c[0].c[1])
  end

  describe "#run" do
    it "reclones properly" do
      orig.reload
      clone.reload
      form.reload

      # Ensure things are set up how we think.
      expect(orig.root_node_id).to eq(clone.root_node_id)
      expect(orig.root_node.option_set_id).to eq(orig.id)
      expect(form.c[0].question.option_set).to eq(clone)
      expect(form.c[1].display_conditions[0].option_node_id).to eq(orig.c[0].c[1].id)

      new_clone = recloner.run[0]

      # Ensure previous refs to the old clone are updated.
      expect(new_clone).not_to eq(clone)

      # Ensure clone now has its own distinct nodes.
      expect(new_clone.root_node_id).not_to eq(orig.root_node_id)
      expect(new_clone.root_node.option_set_id).to eq(new_clone.id)
      expect(OptionNode.where(option_set_id: new_clone.id).count).to eq(7)

      # Ensure question previously pointing at clone is updated to new_clone.
      expect(form.c[0].question.reload.option_set_id).to eq(new_clone.id)

      # Ensure condition updated to equivalent node in new set.
      expect(form.c[1].reload.display_conditions[0].option_node_id).to eq(new_clone.c[0].c[1].id)
    end
  end
end
