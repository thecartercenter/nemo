# frozen_string_literal: true

require "rails_helper"

feature "question index", js: true do
  include_context "search"
  include_context "bulk destroy"
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }
  let(:delete_link_name) { "Delete Multiple Questions" }
  let(:klass) { Question }

  before do
    login(admin)
  end

  describe "bulk destroy not paginated" do
    let!(:questions) { create_list(:question, 4, mission: mission) }
    let!(:question1) { create(:question, mission: mission, code: "BallotBoxes") }

    context "unfiltered" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all on page", expect_to_delete: 5
    end

    context "filtered" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all on page", expect_to_delete: 1, query: "code:BallotBoxes"
    end

    context "select nothing" do
      it_behaves_like "select nothing"
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
      it_behaves_like "select all on page", expect_to_delete: 2
    end

    context "unfiltered select all" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", expect_to_delete: 10
    end

    context "filtered select all" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", expect_to_delete: 5, query: "type:integer"
    end
  end
end
