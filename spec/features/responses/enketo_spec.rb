# frozen_string_literal: true

require "rails_helper"

feature "enketo form rendering and submission", js: true do
  include_context "form design conditional logic"
  include_context "odk submissions"

  let(:user) { create(:user) }
  let(:form) { create(:form, :live, question_types: %w[text]) }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, enketo: 1} }
  let(:form_params) { params.merge(form_id: form.id) }
  let(:latest_response_params) { params.merge(id: Response.order(:created_at).last.shortcode) }
  let(:r1_params) { params.merge(id: r1.shortcode) }
  # Note: "nemo answer" will appear in NEMO, and "*value1*" will appear in Enketo via the XML attached below.
  let(:r1) { create(:response, form: form, answer_values: "nemo answer") }

  before do
    login(user)

    ODK::FormRenderJob.perform_now(form)

    # Make it seem like it was submitted by ODK in the first place.
    submission_file = prepare_and_upload_submission_file("single_question.xml")
    r1.update!(odk_xml: submission_file, source: "odk")
  end

  it "renders blank" do
    visit(new_response_path(form_params))
    expect_enketo_content
  end

  it "shows existing response" do
    visit(response_path(r1_params))
    expect_enketo_content(action: "View")

    expect_filled_in_enketo_value("*value1*")
  end

  it "submits new response" do
    visit(new_response_path(form_params))
    expect_enketo_content

    fill_in("Text Question Title 1", with: "new answer")
    click_button("Save")
    expect(page).to have_content("Success: Response created successfully")

    visit(edit_response_path(latest_response_params))
    expect_filled_in_enketo_value("new answer")
  end

  it "edits existing response" do
    visit(edit_response_path(r1_params))
    expect_enketo_content
    expect_filled_in_enketo_value("*value1*")

    fill_in("Text Question Title 1", with: "") # Weird Capybara behavior: unset the value before resetting.
    fill_in("Text Question Title 1", with: "baz")
    click_button("Save")
    expect(page).to have_content("Success: Response updated successfully")

    visit(response_path(r1_params))
    expect_filled_in_enketo_value("baz")
  end

  private

  # Make sure we're actually using Enketo, not the NEMO editor by default.
  def expect_enketo_content(action: "Edit")
    expect(page).to have_content(form.name)
    expect(page).to have_content(form.c[0].name)
    expect(page).to have_content("#{action} with NEMO")
    expect(page).to have_content("Powered by") # suffix "Enketo" is an image, not text.
  end
end
