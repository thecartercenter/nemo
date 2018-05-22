# frozen_string_literal: true

require "spec_helper"

describe "response tree" do
  # form with repeat group
  context "simple form" do
    let(:form1) { create(:form, question_types: %w[text text text]) }

    it "should produce a simple tree from a form with three children" do
      response_tree = Results::ResponseTreeBuilder.new(form1).build
      # same number of leaves at the root
      expect(response_tree.root_answers.count).to eq form1.root_questionings.count

      # expect to be the same qing_ids
      expect(response_tree.root_answers.map(&:questioning_id))
        .to include(form1.root_questionings[0].id, form1.root_questionings[1].id,
          form1.root_questionings[2].id)

      # same ranks
      expect(response_tree.root_answers.map(&:new_rank))
        .to include(form1.root_questionings[0].rank, form1.root_questionings[1].rank,
          form1.root_questionings[2].rank)
    end
  end

  context "forms with groups" do
    let(:form2) { create(:form, question_types: ["text", %w[select_one text], "text"]) }

    it "should produce the correct tree" do
      response_tree = Results::ResponseTreeBuilder.new(form2).build

      puts response_tree.children.inspect
      # same number of children at the root
      expect(response_tree.children.length).to eq form2.root_group.children.length

      # expect to include one answer group
      expect(response_tree.children.map(&:class)).to include(AnswerGroup)

      # expect to be the same qing_ids
      expect(response_tree.children.map(&:questioning_id))
        .to eq(form2.root_group.children.map(&:id))

      # expect to be the same qing_ids
      expect(response_tree.children.map(&:new_rank))
        .to eq(form2.root_group.children.map(&:rank))

      # expect appropriate number of children in the group
      expect(response_tree.children.descendants.length).to eq 2
    end
  end

  context "multilevel answer forms" do
    let(:form3) { create(:form, question_types: %w[text multilevel_select_one]) }

    it "should create the appropriate multilevel answer tree" do
      response_tree = Results::ResponseTreeBuilder.new(form3).build

      expect(response_tree.children[0].class).to eq AnswerSet
      expect(response_tree.children[1].class).to eq Answer

      expect(response_tree.children[0].children[0].class).to eq Answer
      expect(response_tree.children[0].children[1].class).to eq Answer
      expect(response_tree.children[0].children.length).to eq 2
    end
  end

  context "repeat group forms" do
    let(:form3) { create(:form, question_types: ["text", {repeating: {items: ["text", "text"]}}]) }
  end
end
