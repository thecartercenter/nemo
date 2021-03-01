# frozen_string_literal: true

# Tests the hint popovers in regular forms and modal forms.
require "rails_helper"

feature "form hints", js: true do
  let(:form) { create(:form, question_types: %w[integer image image]) }
  let(:mission_name) { get_mission.compact_name }
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  scenario "question form" do
    visit(new_question_path(mode: "m", mission_name: mission_name, locale: "en"))
    expect_hint_to_show_and_hide(
      selector: ".question_code a.hint",
      text: "A short codename (between 2-20 characters)"
    )
  end

  scenario "form form" do
    visit(new_form_path(mode: "m", mission_name: mission_name, locale: "en"))
    expect_hint_to_show_and_hide(
      selector: ".form_name a.hint",
      text: "A descriptive name"
    )
  end

  scenario "modal form" do
    visit(new_question_path(mode: "m", mission_name: mission_name, locale: "en"))
    select("Select One", from: "Type")
    click_link("Create Option Set")
    wait_modal_to_be_visible

    # This is required for the spec to pass but not sure why.
    # Best theory is that as the modal is animating down, the hints won't show.
    # So you have to wait for the modal to be fully animated in (even after it's visible).
    # I couldn't find a way to do this using `expect`.
    sleep(1)

    expect_hint_to_show_and_hide(
      selector: ".option_set_name a.hint",
      text: "A name that summarizes this set of options."
    )
  end

  def expect_hint_to_show_and_hide(selector:, text:)
    find(selector).click
    expect(page).to have_content(text)

    # Clicking on the popover itself shouldn't hide the popover.
    find("div.popover-body").click
    expect(page).to have_content(text)

    # Clicking elsewhere on the page should hide the popover.
    find("body").click
    expect(page).not_to have_content(text)
  end
end
