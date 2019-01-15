# frozen_string_literal: true

require "rails_helper"

feature "response index", js: true do
  include_context "search"
  include_context "batch delete"
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  describe "bulk destroy not paginated" do
    let!(:responses) { create_list(:response, 5, mission: mission) }

    context "unfiltered" do
      it_behaves_like "select all on page", link: "Delete Selected", klass: "responses", num: 5
    end

    context "filtered" do
      before do
        r = Response.last
        r.reviewed = true
        r.save!
      end
      it_behaves_like "select all on page", link: "Delete Selected", klass: "responses", num: 1, query: "reviewed:1"
    end

    context "select nothing" do
      it_behaves_like "select nothing", "responses", "Delete Selected"
    end
  end

  describe "bulk destroy paginated" do
    let!(:responses) { create_list(:response, 50, mission: mission, reviewed: true) }
    let!(:responses_un) { create_list(:response, 50, mission: mission) }

    context "unfiltered select page" do
      it_behaves_like "select all on page", link: "Delete Selected", klass: "responses", num: 20
    end

    context "unfiltered select all" do
      it_behaves_like "select all that exist", klass: "responses", num: 100, link: "Delete Selected"
    end

    context "filtered select all" do
      it_behaves_like "select all that exist", klass: "responses", num: 50, link: "Delete Selected", query: "reviewed:1"
    end
  end
end
