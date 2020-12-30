# frozen_string_literal: true

require "rails_helper"

# This spec covers bulk destroy and select/deselect all logic for all index pages.
feature "user bulk destroy", js: true do
  include_context "search"
  include_context "bulk destroy"
  let(:admin) { create(:admin, name: "Alpha") } # So that this user comes first in the list.
  let(:mission) { get_mission }
  let(:delete_link_name) { "Delete" }
  let(:klass) { User }

  before do
    login(admin)
  end

  describe "unpaginated" do
    let!(:coordinators) { create_list(:user, 5, mission: mission) }
    let!(:enumerators) { create_list(:user, 5, mission: mission, role_name: :enumerator) }

    context "unfiltered" do
      let!(:preserved_obj) { admin.name }
      it_behaves_like "select all on page", expect_to_delete: 11
      it_behaves_like "select all on page", uncheck_one: true, expect_to_delete: 10
    end

    context "filtered" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all on page", expect_to_delete: 5, query: "role:enumerator"
    end

    context "select nothing" do
      it_behaves_like "select nothing"
    end
  end

  describe "paginated" do
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
      stub_const(UsersController, "PER_PAGE", 3)
    end

    context "unfiltered select current page" do
      let!(:preserved_obj) { "Delta" }
      it_behaves_like "select all on page", expect_to_delete: 3
      it_behaves_like "select all on page", uncheck_one: true, expect_to_delete: 2
    end

    context "unfiltered select all pages" do
      let!(:preserved_obj) { admin.name }
      it_behaves_like "select all that exist", expect_to_delete: 11
      it_behaves_like "select all that exist", uncheck_one: true, expect_to_delete: 2
    end

    context "filtered select all pages" do
      let!(:preserved_obj) { nil }
      it_behaves_like "select all that exist", expect_to_delete: 5, query: "role:enumerator"
      it_behaves_like "select all that exist", uncheck_one: true, expect_to_delete: 2,
                                               query: "role:enumerator"
    end
  end
end
