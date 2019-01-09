# frozen_string_literal: true

require "rails_helper"

feature "user index", js: true do
  include_context "search"
  include_context "batch delete"
  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  describe "bulk destroy not paginated" do
    let!(:coordinators) { create_list(:user, 5, mission: mission) }
    let!(:enumerators) { create_list(:user, 5, mission: mission, role_name: :enumerator) }

    context "unfiltered" do
      it_behaves_like "select all on page", link: "Delete Multiple Users", klass: "users", num: 11
    end

    context "filtered" do
      it_behaves_like "select all on page", link: "Delete Multiple Users", klass: "users", num: 5, query: "role:enumerator"
    end

    context "select nothing" do
      it_behaves_like "select nothing", "users", "Delete Multiple Users"
    end

  end

  describe "bulk destroy paginated" do
    let!(:coordinators) { create_list(:user, 55, mission: mission) }
    let!(:enumerators) { create_list(:user, 55, mission: mission, role_name: :enumerator) }

    context "unfiltered select page" do
      it_behaves_like "select all on page", link: "Delete Multiple Users", klass: "users", num: 50
    end

    context "unfiltered select all" do
      it_behaves_like "select all that exist", klass: "users", num: 111, link: "Delete Multiple Users"
    end

    # context "filtered select all" do
    #   it_behaves_like "select all that exist", klass: "users", num: 55, link: "Delete Multiple Users", query: "role:enumerator"
    # end

  end
end
