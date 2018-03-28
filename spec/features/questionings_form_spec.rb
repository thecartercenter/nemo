require "spec_helper"

describe "questionings form", js: true  do
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  context "for mission-based" do
    let(:form) { create(:form, question_types: %w[text text]) }
    let(:qing) { form.questionings.last }

    context "when unpublished" do
      it "should display all fields as editable" do
        visit(edit_questioning_path(qing, locale: "en", mode: "m", mission_name: get_mission.compact_name))
        expect_editable("required", true)
        expect_editable("hidden", true)
        expect_editable("display_logic", true, field_type: "select")
        expect_editable("skip_logic", true, field_type: "select")
      end

      it "should display logic iff metadata is not selected on a metadata type question" do
        visit(edit_questioning_path(qing, locale: "en", mode: "m", mission_name: get_mission.compact_name))
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
    end

    context "when published" do
      it "should display all fields as not editable" do
        form.publish!
        visit(edit_questioning_path(qing, locale: "en", mode: "m", mission_name: get_mission.compact_name))
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
      visit(edit_questioning_path(qing, locale: "en", mode: "m", mission_name: get_mission.compact_name))
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
