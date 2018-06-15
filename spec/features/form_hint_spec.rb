# Tests the hint popovers in regular forms and modal forms.
require 'rails_helper'

feature 'form hints', js: true do
  let(:form) { create(:form, question_types: %w(integer image image)) }
  let(:mission_name) { get_mission.compact_name }

  before do
    @user = create(:user, role_name: "coordinator")
    login(@user)
  end

  scenario "regular form" do
    visit(new_question_path(mode: "m", mission_name: mission_name, locale: "en"))
    expect_hint_to_show_and_hide(
      selector: ".question_code a.hint",
      text: "A short codename (between 2-20 characters)"
    )
  end

  scenario "modal form" do
    visit(new_question_path(mode: "m", mission_name: mission_name, locale: "en"))
    select("Select One", from: "Type")
    click_link("Create New Option Set")
    wait_modal_to_be_visible

    # This is required for the spec to pass but not sure why.
    # Best theory is that as the modal is animating down, the hints won't show.
    # So you have to wait for the modal to be fully animated in (even after it's visible).
    # I couldn't find a way to do this using `expect`.
    sleep 1

    expect_hint_to_show_and_hide(
      selector: ".option_set_name a.hint",
      text: "A name that summarizes this set of options."
    )
  end

  scenario "response form" do
    form.c[0].question.update!(hint: "A fun hint.")
    form.c[2].question.update!(hint: "An image hint")
    # Response form code is distinct from regular form code in some areas.
    visit(new_response_path(mode: "m", mission_name: mission_name, locale: "en", form_id: form.id))
    expect_hint_to_show_and_hide(
      selector: "div[data-qing-id=\"#{form.c[0].id}\"] a.hint",
      text: "A fun hint"
    )
    expect_hint_to_show_and_hide(
      selector: "div[data-qing-id=\"#{form.c[1].id}\"] a.hint",
      text: "Accepted formats are: jpg,"
    )
    expect_hint_to_show_and_hide(
      selector: "div[data-qing-id=\"#{form.c[2].id}\"] a.hint",
      text: "An image hint. The image should be"
    )
  end

  def expect_hint_to_show_and_hide(selector:, text:)
    find(selector).click
    expect(page).to have_content(text)
    find("body").click
    expect(page).not_to have_content(text)
  end
end
