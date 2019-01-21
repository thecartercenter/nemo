# frozen_string_literal: true

require "rails_helper"

feature "question index", js: true do
  include_context "search"
  include_context "batch delete"
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  describe "bulk destroy not paginated" do
    let!(:questions) { create_list(:question, 4, mission: mission) }
    let!(:question1) { create(:question, mission: mission, code: "BallotBoxes") }

    context "unfiltered" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all on page", link: "Delete Multiple Questions", klass: "questions",
                                            num: 5
    end

    context "filtered" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all on page", link: "Delete Multiple Questions",
                                            klass: "questions",
                                            num: 1,
                                            query: "code:BallotBoxes"
    end

    context "select nothing" do
      it_behaves_like "select nothing", "questions", "Delete Multiple Questions"
    end
  end

  describe "bulk destroy paginated" do
    let!(:integer_questions) { create_list(:question, 50, mission: mission, qtype_name: "integer") }
    let!(:text_questions) { create_list(:question, 50, mission: mission, qtype_name: "text") }

    context "unfiltered select page" do
      let!(:preserved_obj) { Question.limit(40).last }
      it_behaves_like "select all on page", link: "Delete Multiple Questions", klass: "questions",
                                            num: 25
    end

    context "unfiltered select all" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", klass: "questions", num: 100,
                                               link: "Delete Multiple Questions"
    end

    context "filtered select all" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", klass: "questions",
                                               num: 50,
                                               link: "Delete Multiple Questions",
                                               query: "type:integer"
    end
  end
end
