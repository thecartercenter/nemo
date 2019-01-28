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
      it_behaves_like "select all on page", link: "Delete Multiple Questions", klass: "questions", num: 5
    end

    context "filtered" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all on page", link: "Delete Multiple Questions", klass: "questions", num: 1,
                                            query: "code:BallotBoxes"
    end

    context "select nothing" do
      it_behaves_like "select nothing", "questions", "Delete Multiple Questions"
    end
  end

  describe "bulk destroy paginated" do
    let!(:integer_questions) do
      [
        create(:question, code: "Bravo", mission: mission, qtype_name: "integer"),
        create(:question, code: "Charlie", mission: mission, qtype_name: "integer"),
        create(:question, code: "Delta", mission: mission, qtype_name: "integer"),
        create(:question, code: "Echo", mission: mission, qtype_name: "integer"),
        create(:question, code: "Foxtrot", mission: mission, qtype_name: "integer")
      ]
    end
    let!(:text_questions) do
      [
        create(:question, code: "Golf", mission: mission, qtype_name: "text"),
        create(:question, code: "Hotel", mission: mission, qtype_name: "text"),
        create(:question, code: "India", mission: mission, qtype_name: "text"),
        create(:question, code: "Juliet", mission: mission, qtype_name: "text"),
        create(:question, code: "Kilo", mission: mission, qtype_name: "text")
      ]
    end

    before do
      stub_const(QuestionsController, "PER_PAGE", 2)
    end

    context "unfiltered select page" do
      let!(:preserved_obj) { "Delta" }
      it_behaves_like "select all on page", link: "Delete Multiple Questions", klass: "questions", num: 2
    end

    context "unfiltered select all" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", klass: "questions", num: 10, link: "Delete Multiple Questions"
    end

    context "filtered select all" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", klass: "questions", num: 5,
                                               link: "Delete Multiple Questions", query: "type:integer"
    end
  end
end
