require "rails_helper"

describe "questionings form", js: true  do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:edit_qing_path) do
    edit_questioning_path(
      qing,
      locale: "en",
      mode: "m",
      mission_name: get_mission.compact_name
    )
  end

  before do
    login(user)
  end

  context "for mission-based" do
    let(:form) { create(:form, question_types: %w[text text]) }
    let(:qing) { form.questionings.last }

    context "when unpublished" do
      it "should display all fields as editable" do
        visit edit_qing_path
        expect_editable("required", true)
        expect_editable("hidden", true)
        expect_editable("display_logic", true, field_type: "select")
        expect_editable("skip_logic", true, field_type: "select")
      end

      it "should display logic iff metadata is not selected on a metadata type question" do
        visit edit_qing_path
        select "Date/Time", from: "Type"
        expect_visible("display_logic", true)
        expect_visible("skip_logic", true)
        select "Form Start Time", from: "Metadata Type"
        expect_visible("display_logic", false)
        expect_visible("skip_logic", false)
        within(:css, ".question_metadata_type") do
          select "", from: "Metadata Type"
        end
        expect_visible("display_logic", true)
        expect_visible("skip_logic", true)
      end

      it "should hide hidden option when metadata field has a value" do
        visit edit_qing_path
        select "Select One", from: "questioning_question_attributes_qtype_name"
        expect_visible("hidden", true)
        select "Date/Time", from: "Type"
        expect_visible("hidden", true)
        select "Form Start Time", from: "Metadata Type"
        expect_visible("hidden", false)
        within(:css, ".question_metadata_type") do
          select "", from: "Metadata Type"
        end
        expect_visible("hidden", true)
      end

      it "should display default only if question type is defaultable" do
        visit edit_qing_path
        select "Select One", from: "questioning_question_attributes_qtype_name"
        expect_editable("default", false)
        select "Text", from: "Type" # Text is defaultable
        expect_editable("default", true)
        select "Select One", from: "Type"
        expect_editable("default", false)
      end

      it "should display readonly only if default is not empty" do
        visit edit_qing_path
        select "Text", from: "Type" # Text is defaultable
        expect_editable("read_only", false)
        fill_in "Default Answer", with: "Test"
        expect_editable("read_only", true)
        fill_in "Default Answer", with: ""
        page.execute_script '$("#questioning_default").trigger("keyup")'
        expect_editable("read_only", false)
      end

      it "should be able to add audio prompt to through questioning form" do
        visit edit_qing_path
        attach_file("Audio Prompt", audio_fixture("powerup.mp3").path)
        click_on "Save"

        # we can still see the audio prompt file
        visit edit_questioning_path(qing, locale: "en", mode: "m", mission_name: get_mission.compact_name)
        expect(page).to have_content("powerup.mp3")
      end
    end

    context "when published" do
      it "should display all fields as not editable" do
        form.publish!
        visit edit_qing_path
        expect_editable("required", false)
        expect_editable("hidden", false)
        expect_editable("display_logic", false, field_type: "select")
        expect_editable("skip_logic", false, field_type: "select")
      end
    end
  end

  context "for unpublished std copy" do
    let(:standard_form) { create(:form, question_types: %w[text text], is_standard: true) }
    let(:copied_form) { standard_form.replicate(mode: :to_mission, dest_mission: get_mission) }
    let(:qing) { copied_form.questionings.last }

    it "should display all fields as editable" do
      visit edit_qing_path
      expect_editable("required", true)
      expect_editable("hidden", true)
      expect_editable("display_logic", true, field_type: "select")
      expect_editable("skip_logic", true, field_type: "select")
    end
  end

  def expect_editable(field, should_be_editable, field_type: "input")
    sel = "div.form-field.questioning_#{field} .widget #{field_type}"
    if should_be_editable
      expect(page).to have_selector(sel)
    else
      expect(page).not_to have_selector(sel)
    end
  end

  def expect_visible(field, should_be_visible)
    sel = "div.form-field.questioning_#{field}"
    if should_be_visible
      expect(page).to have_selector(sel)
    else
      expect(page).not_to have_selector(sel)
    end
  end
end
