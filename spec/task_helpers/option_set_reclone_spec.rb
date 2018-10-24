# frozen_string_literal: true

require "rails_helper"
require "./lib/task_helpers/option_set_reclone"

describe OptionSetReclone do
  let!(:orig) { create(:option_set, multilevel: true) }
  let!(:clone) { orig.replicate(mode: :clone) }
  let!(:form) { create(:form, question_types: %w[select_one integer]) }
  subject(:recloner) { described_class.new }

  before do
    clone.update_column(:root_node_id, orig.root_node_id)

    # Clear out the option nodes that wouldn't have been there before this bug was fixed.
    OptionNode.where(option_set: clone).delete_all!

    # Make the condition on the form point to the cloned option set.
    form.c[0].question.update!(option_set: clone)
    form.c[1].display_conditions.create!(ref_qing: form.c[0], op: "eq", option_node: clone.c[0].c[0])
  end

  describe "#run" do
    it do
      orig.reload
      clone.reload
      form.reload

      # Ensure things are set up how we think.
      expect(orig.root_node_id).to eq(clone.root_node_id)
      expect(orig.root_node.option_set_id).to eq(orig.id)
      expect(form.c[0].question.option_set).to eq(clone)
      expect(form.c[1].display_conditions[0].option_node_id).to eq(orig.c[0].c[0].id)

      new_clone = subject.run[0]

      # Ensure previous refs to the old clone are updated.
      expect(new_clone).not_to eq(clone)

      # Ensure clone now has its own distinct nodes.
      expect(new_clone.root_node_id).not_to eq(orig.root_node_id)
      expect(new_clone.root_node.option_set_id).to eq(new_clone.id)
      expect(OptionNode.where(option_set_id: new_clone.id).count).to eq(7)

      # Ensure question previously pointing at clone is updated to new_clone.
      expect(form.c[0].question.reload.option_set_id).to eq(new_clone.id)
    end
  end
end
