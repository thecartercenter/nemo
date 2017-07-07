require 'spec_helper'

describe QingGroupOdkPartitioner do

  let(:form) { create(:form, question_types: [["text","text","multilevel_select_one","text"],["text", "text", "text"]]) }

  describe "#organize" do

    it "splits qing groups in order to remove multilevel questions from them" do
      results = QingGroupOdkPartitioner.new.fragment(form.sorted_children.first)

      expect(results.size).to eq(3)
      expect(results[0]).to be_a QingGroupFragment
      expect(results[1]).to be_a QingGroupFragment
      expect(results[2]).to be_a QingGroupFragment
      expect(results[0].children.count).to eq 2
      expect(results[1].children.count).to eq 1
      expect(results[2].children.count).to eq 1
      expect(results[0].children.first.multilevel?).to be_nil
      expect(results[1].children.first.multilevel?).to be true
      expect(results[2].children.first.multilevel?).to be_nil

    end

    it "return nil if there isn't a multilevel question on it" do
      result = QingGroupOdkPartitioner.new.fragment(form.sorted_children.last)

      expect(result).to be_nil
    end

    it "returns nil if the group is not a bottom-level group" do
      result = QingGroupOdkPartitioner.new.fragment(form)

      expect(result).to be_nil
    end

    it "returns nil if has no children" do
      result = QingGroupOdkPartitioner.new.fragment(form.sorted_children.first.sorted_children.first)

      expect(result).to be_nil
    end
  end
end
