# frozen_string_literal: true

require "rails_helper"

describe ResponseNode do
  # We trust that closure tree's auto-reordering works generally, but it is not aware of soft delete.
  # Need to make sure that works too.
  describe "automatic reordering on delete" do
    include_context "response tree"
    let(:form) do
      create(:form, question_types: ["text", "text", {repeating: {items: %w[text text]}}, "text"])
    end
    let(:response) do
      create(:response, form: form, answer_values: ["x", "x", {repeating: [%w[x x], %w[y y]]}, "x"])
    end
    let(:reloaded_response) { Response.find(response.id) }

    it "deleting a top level answer" do
      response.c[1].destroy
      # expect_children automatically checks new_rank
      expect_children(
        reloaded_response.root_node,
        %w[Answer AnswerGroupSet Answer],
        [form.c[0], form.c[2], form.c[3]].map(&:id)
      )
    end

    it "deleting an AnswerGroup" do
      response.c[2].c[0].destroy
      expect_children(
        reloaded_response.c[2],
        %w[AnswerGroup],
        [form.c[2].id]
      )
      expect_children(
        reloaded_response.c[2].c[0],
        %w[Answer Answer],
        form.c[2].c.map(&:id),
        %w[y y]
      )
    end
  end
end
