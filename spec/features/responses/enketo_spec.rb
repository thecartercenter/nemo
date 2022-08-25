# frozen_string_literal: true

require "rails_helper"

# Developer note:
#
# These full integration specs are SLOW to run (several seconds each), so
# please consider writing lower-level specs when possible, or at least minimize page navigation.
#
# Please also consider that enketo is an external library with its own test suite,
# so the nemo codebase cannot be responsible for ensuring that enketo continues functioning as advertised.
# These specs should be limited to ensuring that the interaction BETWEEN nemo and enketo continues working.
#
feature "enketo form rendering and submission", js: true do
  include_context "form design conditional logic for Enketo"
  include_context "odk submissions"

  let(:save_fixtures) { true }
  let(:user) { create(:user) }
  let(:form) { create(:form, :live, question_types: %w[text]) }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, enketo: 1} }
  let(:form_params) { params.merge(form_id: form.id) }
  let(:latest_response_params) { params.merge(id: Response.order(:created_at).last.shortcode) }

  # Note: "nemo answer" will appear in NEMO, and "enketo answer"
  # will appear in Enketo via the XML attached below.
  let(:r1) { create(:response, form: form, answer_values: "nemo answer") }
  let(:r1_params) { params.merge(id: r1.shortcode) }
  let(:nemo_r1_params) { r1_params.merge(enketo: nil) }

  before do
    login(user)
    ODK::FormRenderJob.perform_now(form)
  end

  context "happy path" do
    before do
      mock_submission(r1)
    end

    it "renders blank" do
      visit(new_response_path(form_params))
      expect_enketo_content
    end

    it "shows existing response" do
      visit(response_path(r1_params))
      expect_enketo_content(action: "View")

      expect_filled_in_value("enketo answer")
    end

    it "submits new response" do
      visit(new_response_path(form_params))
      expect_enketo_content

      fill_in_value("new answer")
      save_and_wait
      expect(page).to have_content("Success: Response created successfully")

      visit(edit_response_path(latest_response_params))
      expect_filled_in_value("new answer")
    end

    it "edits existing response" do
      visit(edit_response_path(r1_params))

      expect(r1.source).to eq("odk")
      expect(r1.modifier).to eq(nil)
      expect(r1.odk_xml.attached?).to be(true)
      original_checksum = r1.odk_xml.checksum
      expect(r1.modified_odk_xml.attached?).to be(false)

      expect_enketo_content
      expect_filled_in_value("enketo answer")
      fill_in_value("edited answer")
      save_and_wait
      expect(page).to have_content("Success: Response updated successfully")

      visit(response_path(r1_params))
      expect_filled_in_value("edited answer")

      r1.reload
      expect(r1.source).to eq("odk")
      expect(r1.modifier).to eq("enketo")
      expect(r1.odk_xml.attached?).to be(true)
      expect(r1.odk_xml.checksum).to eq(original_checksum)
      expect(r1.modified_odk_xml.attached?).to be(true)
    end
  end

  context "skip logic" do
    let(:form) { create(:form, :live, question_types: %w[text text text text]) }
    let(:qings) { form.questionings }
    let(:response) { create(:response, form: form, answer_values: []) } # Answers filled in via XML below.

    # skip over a required question to a later questioning
    before do
      qings[1].update!(required: true)

      # Skip from [0] to [2] if [0] is equal to "skip"
      create(
        :skip_rule,
        source_item: qings[0],
        destination: "item",
        dest_item_id: qings[2].id,
        conditions_attributes: [{left_qing_id: qings[0].id, op: "eq", value: "skip"}]
      )

      ODK::FormRenderJob.perform_now(form)

      submission_file = prepare_odk_response_fixture("enketo_skip_logic", form, return_file: true, values: [
        "skip", nil, "bar", "baz"
      ])
      response.update!(odk_xml: submission_file, source: "odk")
    end

    it "works even when editing retroactively" do
      # Make sure the form is valid as-is.
      visit(edit_response_path(latest_response_params))
      within(all(".question")[0]) { expect_filled_in_value("skip") }
      save_and_wait
      expect(page).to have_content("Success: Response updated successfully")

      # Make sure the skip logic validates new edits,
      # e.g. after the required questioning becomes relevant again.
      visit(edit_response_path(latest_response_params))
      within(all(".question")[0]) { expect_filled_in_value("skip") }
      within(all(".question")[0]) { fill_in_value("unskip") }
      save_only
      page.driver.browser.switch_to.alert.accept
      expect(page).to have_content("This field is required")
      within(all(".question")[1]) { fill_in_value("not blank anymore") }
      expect(page).not_to have_content("This field is required")
      save_and_wait
      expect(page).to have_content("Success: Response updated successfully")
    end
  end

  context "internationalization" do
    before do
      get_mission.setting.update!(preferred_locales_str: "en,fr")
      form.c[0].question.update!(name_fr: "La Question En Français")
      ODK::FormRenderJob.perform_now(form)
    end

    it "renders in french" do
      visit(new_response_path(form_params.merge(locale: :fr)))
      expect(page).to have_content("Modifier avec NEMO")
      expect(page).to have_content("La Question En Français")
    end
  end

  context "warnings" do
    before do
      mock_submission(r1)
    end

    context "when submitted by enketo" do
      before do
        r1.update!(source: "enketo")
      end

      it "shows alert in nemo" do
        visit(response_path(nemo_r1_params))
        expect_nemo_content(action: "View")
        expect(page).to have_content("response was most recently created or modified by the Enketo editor")
      end
    end

    context "when edited previously with nemo" do
      before do
        r1.update!(modifier: "web")
      end

      it "shows alert in enketo" do
        visit(response_path(r1_params))
        expect_enketo_content(action: "View")
        expect(page).to have_content("response was most recently modified by the NEMO editor")
      end
    end

    context "when edited previously with enketo" do
      before do
        r1.update!(modifier: "enketo")
      end

      it "shows alert in nemo" do
        visit(response_path(nemo_r1_params))
        expect_nemo_content(action: "View")
        expect(page).to have_content("response was most recently created or modified by the Enketo editor")
      end
    end
  end

  # Permissions are largely tested in response_ability_spec.
  context "permissions" do
    let(:user) { create(:user, role_name: "enumerator") }

    before do
      mock_submission(r1)
    end

    it "disallows viewing existing response" do
      visit(response_path(r1_params))
      expect(page).to have_content("You are not authorized")
    end
  end

  private

  # Make it seem like the response was submitted by ODK in the first place.
  def mock_submission(response)
    submission_file = prepare_odk_response_fixture("single_question", form, return_file: true, values: [
      "enketo answer"
    ])
    response.update!(odk_xml: submission_file, source: "odk")
  end

  # Make sure we're actually using Enketo, not the NEMO editor by default.
  def expect_enketo_content(action: "Edit")
    expect(page).to have_content(form.name)
    expect(page).to have_content(form.c[0].name)
    expect(page).to have_content("#{action} with NEMO")
    expect(page).to have_content("Powered by") # suffix "Enketo" is an image, not text.
  end

  def expect_nemo_content(action: "Edit")
    expect(page).to have_content(form.name)
    expect(page).to have_content(form.c[0].name)
    expect(page).to have_content("#{action} with Enketo")
    expect(page).not_to have_content("Powered by") # suffix "Enketo" is an image, not text.
  end
end
