require "spec_helper"

describe "response tree" do
  # form with repeat group
  context "simple form"
    let(:form1) { create(:form, question_types: ["text", "text", "text"])}

    it "should produce a simple tree with three children" do
      response_tree = Results::ResponseTreeBuilder.new(form1).build
      # same number of leaves at the root
      expect(response_tree.root_answers.count).to eq form1.root_questionings.count
      # should be of the same type of Answers, new rank
    end
  end

  context "more complex forms" do
  end
end
