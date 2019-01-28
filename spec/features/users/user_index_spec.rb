# frozen_string_literal: true

require "rails_helper"

feature "user index", js: true do
  include_context "search"
  include_context "batch delete"
  let(:admin) { create(:admin, name: "Alpha") } # So that this user comes first in the list.
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  describe "bulk destroy not paginated" do
    let!(:coordinators) { create_list(:user, 5, mission: mission) }
    let!(:enumerators) { create_list(:user, 5, mission: mission, role_name: :enumerator) }

    context "unfiltered" do
      let!(:preserved_obj) { admin.name }
      it_behaves_like "select all on page", link: "Delete Multiple Users", klass: "users", num: 11
    end

    context "filtered" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all on page", link: "Delete Multiple Users", klass: "users", num: 5,
                                            query: "role:enumerator"
    end

    context "select nothing" do
      it_behaves_like "select nothing", "users", "Delete Multiple Users"
    end
  end

  describe "bulk destroy paginated" do
    let!(:coordinators) do
      [
        create(:user, name: "Bravo", mission: mission, role_name: :coordinator),
        create(:user, name: "Charlie", mission: mission, role_name: :coordinator),
        create(:user, name: "Delta", mission: mission, role_name: :coordinator),
        create(:user, name: "Echo", mission: mission, role_name: :coordinator),
        create(:user, name: "Foxtrot", mission: mission, role_name: :coordinator)
      ]
    end
    let!(:enumerators) do
      [
        create(:user, name: "Golf", mission: mission, role_name: :enumerator),
        create(:user, name: "Hotel", mission: mission, role_name: :enumerator),
        create(:user, name: "India", mission: mission, role_name: :enumerator),
        create(:user, name: "Juliet", mission: mission, role_name: :enumerator),
        create(:user, name: "Kilo", mission: mission, role_name: :enumerator)
      ]
    end

    before do
      stub_const(UsersController, "PER_PAGE", 2)
    end

    context "unfiltered select page" do
      let!(:preserved_obj) { "Charlie" }
      it_behaves_like "select all on page", link: "Delete Multiple Users", klass: "users", num: 2
    end

    context "unfiltered select all pages" do
      let!(:preserved_obj) { admin.name }
      it_behaves_like "select all that exist", klass: "users", num: 11, link: "Delete Multiple Users"
    end

    context "filtered select all pages" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", klass: "users", num: 5, link: "Delete Multiple Users",
                                               query: "role:enumerator"
    end
  end
end
