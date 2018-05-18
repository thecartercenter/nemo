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
        .to eq(form1.root_questionings.map(&:id))

      # same ranks
      expect(response_tree.root_answers.map(&:new_rank))
        .to eq(form1.root_questionings.map(&:rank))
    end
  end

  # context "more complex forms" do
  # end
end
