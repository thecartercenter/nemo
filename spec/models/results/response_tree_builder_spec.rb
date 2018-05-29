# frozen_string_literal: true

require "spec_helper"

describe Results::ResponseTreeBuilder do
  let(:response_tree) { Results::ResponseTreeBuilder.new(form).build }

  context "simple form" do
    let(:form) { create(:form, question_types: %w[text text text]) }
    it "should produce a simple tree from a form with three children" do
      expect_children(response_tree, %w[Answer Answer Answer], form.c.map(&:id))
    end
  end

  context "forms with a group" do
    let(:form) { create(:form, question_types: ["text", %w[select_one text], "text"]) }

    it "should produce the correct tree" do
      expect_children(response_tree, %w[Answer AnswerGroup Answer], form.c.map(&:id))
      expect_children(response_tree.children[1], %w[Answer Answer], form.c[1].c.map(&:id))
    end
  end

  context "multilevel answer forms" do
    let(:form) { create(:form, question_types: %w[text multilevel_select_one]) }

    it "should create the appropriate multilevel answer tree" do
      expect_children(response_tree, %w[Answer AnswerSet], form.c.map(&:id))
      expect_children(response_tree.children[0], %w[Answer Answer],
        [form.c[1].id, form.c[1].id])
    end
  end

  context "repeat group forms" do
    let(:form) { create(:form, question_types: ["text", {repeating: {items: %w[text text]}}]) }

    it "should create the appropriate repeating group tree" do
      expect_children(response_tree, %w[Answer AnswerGroupSet], form.c.map(&:id))
      expect_children(response_tree.children[0], %w[AnswerGroup], [form.c[1].id])
      expect_children(response_tree.children[0].children[0], %w[Answer Answer],
        form.c[1].c.map(&:id))
    end
  end

  private

  def expect_children(node, types, qing_ids)
    children = node.children.sort_by(&:new_rank)
    expect(children.map(&:type)).to eq types
    expect(children.map(&:questioning_id)).to eq qing_ids
    expect(children.map(&:new_rank)).to eq((1..children.size).to_a)
  end
end
