# frozen_string_literal: true

require "spec_helper"

describe "response tree" do
  context "simple form" do
    let(:form) { create(:form, question_types: %w[text text text]) }

    it "should produce a simple tree from a form with three children" do
      response_tree = Results::ResponseTreeBuilder.new(form).build
      expect_children(response_tree, %w[Answer Answer Answer], form.children.map(&:id))
    end
  end

  context "forms with a group" do
    let(:form) { create(:form, question_types: ["text", %w[select_one text], "text"]) }

    it "should produce the correct tree" do
      response_tree = Results::ResponseTreeBuilder.new(form).build

      expect_children(response_tree, %w[Answer AnswerGroup Answer], form.children.map(&:id))
      expect_children(response_tree.children[1], %w[Answer Answer], form.children[1].children.map(&:id))
    end
  end

  context "multilevel answer forms" do
    let(:form) { create(:form, question_types: %w[text multilevel_select_one]) }

    it "should create the appropriate multilevel answer tree" do
      response_tree = Results::ResponseTreeBuilder.new(form).build

      expect_children(response_tree, %w[AnswerSet Answer], form.children.map(&:id))
      expect_children(response_tree.children[0], %w[Answer Answer], form.children[0].children.map(&:id))
    end
  end

  context "repeat group forms" do
    let(:form) { create(:form, question_types: ["text", {repeating: {items: %w[text text]}}]) }

    it "should create the appropriate repeating group tree" do
      response_tree = Results::ResponseTreeBuilder.new(form).build

      expect_children(response_tree, %w[AnswerGroupSet Answer], form.children.map(&:id))
      expect_children(response_tree.children[0], %w[AnswerGroup], [form.children[0].id])
      expect_children(response_tree.children[0].children[0], %w[Answer Answer],
        form.children[0].children.map(&:id))
    end
  end

  private

  def expect_children(node, types, qing_ids)
    expect(node.children.map(&:type)).to eq types
    expect(node.children.map(&:questioning_id)).to eq qing_ids
    expect(node.children.map(&:new_rank).sort).to eq((1..node.children.size).to_a)
  end
end
