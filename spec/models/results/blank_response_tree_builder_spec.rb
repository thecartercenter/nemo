# frozen_string_literal: true

require "rails_helper"

describe Results::BlankResponseTreeBuilder do
  include_context "response tree"

  let(:response) { create(:response, form: form, answer_values: nil) }
  let(:response_tree) { Results::BlankResponseTreeBuilder.new(response).build }

  context "simple form" do
    let(:form) { create(:form, question_types: %w[text text text]) }

    it "should produce a simple tree from a form with three children" do
      expect_root(response_tree, form)
      expect_children(response_tree, %w[Answer Answer Answer], form.c.map(&:id))
    end
  end

  context "forms with a group" do
    let(:form) { create(:form, question_types: ["text", %w[select_one text], "text"]) }

    it "should produce the correct tree" do
      expect_root(response_tree, form)
      expect_children(response_tree, %w[Answer AnswerGroup Answer], form.c.map(&:id))
      expect_children(response_tree.c[1], %w[Answer Answer], form.c[1].c.map(&:id))
    end
  end

  context "multilevel answer forms" do
    let(:form) { create(:form, question_types: %w[text multilevel_select_one]) }

    it "should create the appropriate multilevel answer tree" do
      expect_root(response_tree, form)
      expect_children(response_tree, %w[Answer AnswerSet], form.c.map(&:id))
      expect_children(response_tree.c[1], %w[Answer Answer], [form.c[1].id, form.c[1].id])
    end
  end

  context "repeat group forms" do
    let(:form) { create(:form, question_types: ["text", {repeating: {items: %w[text text]}}]) }

    it "should create the appropriate repeating group tree" do
      expect_root(response_tree, form)
      expect_children(response_tree, %w[Answer AnswerGroupSet], form.c.map(&:id))
      expect_children(response_tree.c[1], %w[AnswerGroup], [form.c[1].id])
      expect_children(response_tree.c[1].c[0], %w[Answer Answer], form.c[1].c.map(&:id))
    end
  end

  context "hidden question" do
    let(:form) { create(:form, question_types: %w[text text text]) }

    before do
      questioning = form.questionings.last
      questioning.update!(hidden: true)
    end

    it "does not include hidden question in the tree" do
      expect_root(response_tree, form)
      expect_children(response_tree, %w[Answer Answer], form.c.reject(&:hidden).map(&:id))
    end
  end
end
