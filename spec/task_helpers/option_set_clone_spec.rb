# frozen_string_literal: true

require "rails_helper"
require "./lib/task_helpers/option_set_clone"

describe OptionSetClone do
  let!(:orig) { create(:option_set, multilevel: true) }
  let!(:copy) { orig.replicate(mode: :clone) }
  let!(:question) { create(:question) }

  subject { described_class.new }

  before do
    copy.root_node = orig.root_node
    copy.save!

    question.option_set_id = copy.id
    question.save!
  end

  describe "#run" do
    it "re-clones option sets with duplicate root node IDs" do
      subject.run

      count = OptionSet.where(root_node_id: orig.root_node_id).count
      expect(count).to eq 1
    end

    it "updates references with cloned IDs" do
      subject.run

      expect(question.reload.option_set_id).to_not eq copy.id
    end
  end
end
