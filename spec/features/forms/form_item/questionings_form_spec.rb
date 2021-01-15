# frozen_string_literal: true

require "rails_helper"

describe "questionings form", js: true  do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:edit_qing_path) do
    edit_questioning_path(qing, locale: "en", mode: "m", mission_name: get_mission.compact_name)
  end

  before do
    login(user)
  end

  context "for mission-based" do
    let(:form) { create(:form, question_types: %w[text text]) }
    let(:qing) { form.questionings.last }

    context "when unpublished" do
      context "with simple form" do
        it "should display all fields as editable" do
          visit(edit_qing_path)
          expect_field_visibility("required", :editable)
          expect_field_visibility("hidden", :editable)
          expect_field_visibility("disabled", :editable)
          expect_field_visibility("display_logic", :editable, field_type: "select")
          expect_field_visibility("skip_logic", :editable, field_type: "select")
        end

        it "should display logic iff metadata is not selected on a metadata type question" do
          visit(edit_qing_path)
          select("Date/Time", from: "Type")
          expect_field_visibility("display_logic", :read_only)
          expect_field_visibility("skip_logic", :read_only)
          select("Form Start Time", from: "Metadata Type")
          expect_field_visibility("display_logic", :hidden)
          expect_field_visibility("skip_logic", :hidden)
          within(:css, ".question_metadata_type") do
            select("", from: "Metadata Type")
          end
          expect_field_visibility("display_logic", :read_only)
          expect_field_visibility("skip_logic", :read_only)
        end

        it "should hide hidden option when metadata field has a value" do
          visit(edit_qing_path)
          select("Select One", from: "questioning_question_attributes_qtype_name")
          expect_field_visibility("hidden", :editable)
          select("Date/Time", from: "Type")
          expect_field_visibility("hidden", :editable)
          select("Form Start Time", from: "Metadata Type")
          expect_field_visibility("hidden", :hidden)
          within(:css, ".question_metadata_type") do
            select("", from: "Metadata Type")
          end
          expect_field_visibility("hidden", :editable)
        end

        it "should not hide disabled option when metadata field has a value" do
          visit(edit_qing_path)
          select("Select One", from: "questioning_question_attributes_qtype_name")
          expect_field_visibility("disabled", :editable)
          select("Date/Time", from: "Type")
          expect_field_visibility("disabled", :editable)
          select("Form Start Time", from: "Metadata Type")
          expect_field_visibility("disabled", :editable)
          within(:css, ".question_metadata_type") do
            select("", from: "Metadata Type")
          end
          expect_field_visibility("disabled", :editable)
        end

        it "should display default only if question type is defaultable" do
          visit(edit_qing_path)
          select("Select One", from: "questioning_question_attributes_qtype_name")
          expect_field_visibility("default", :hidden)
          select("Text", from: "Type") # Text is defaultable
          expect_field_visibility("default", :editable)
          select("Select One", from: "Type")
          expect_field_visibility("default", :hidden)
        end

        it "should display preload_last_saved only if question type is lastpreloadable" do
          visit(edit_qing_path)
          select("Image", from: "questioning_question_attributes_qtype_name")
          expect_field_visibility("preload_last_saved", :hidden)
          select("Text", from: "Type") # Text is lastpreloadable
          expect_field_visibility("preload_last_saved", :editable)
          select("Image", from: "Type")
          expect_field_visibility("preload_last_saved", :hidden)
        end

        it "should display readonly only if default is not empty" do
          visit(edit_qing_path)
          select("Text", from: "Type") # Text is defaultable
          expect_field_visibility("read_only", :hidden)
          fill_in("Default Answer", with: "Test")
          expect_field_visibility("read_only", :editable)
          fill_in("Default Answer", with: "")
          page.execute_script('$("#questioning_default").trigger("keyup")')
          expect_field_visibility("read_only", :hidden)
        end

        it "should display required only if not read_only and no metadata type" do
          visit(edit_qing_path)
          expect_field_visibility("required", :editable)

          select("Date/Time", from: "Type")
          select("Form Start Time", from: "Metadata Type")
          expect_field_visibility("required", :hidden)

          select("", from: "Metadata Type")
          expect_field_visibility("required", :editable)

          select("Text", from: "Type", match: :prefer_exact) # Text is defaultable
          fill_in("Default Answer", with: "Test")
          check("Read Only")
          expect_field_visibility("required", :hidden)
        end

        it "should be able to add media prompt to through questioning form" do
          visit(edit_qing_path)
          attach_file("Media Prompt", audio_fixture("powerup.mp3").path)
          click_on("Save")

          # we can still see the media prompt file
          visit(edit_questioning_path(qing, locale: "en", mode: "m", mission_name: get_mission.compact_name))
          expect(page).to have_content(".mp3")
        end

        it "should hide default field when if preload_last_saved is checked" do
          visit(edit_qing_path)
          expect_field_visibility("default", :editable)
          check("Preload Last Answer?")
          expect_field_visibility("default", :hidden)
        end
      end

      context "when regular and multilevel option sets present" do
        let!(:regular) { create(:option_set, name: "Regular") }
        let!(:multilevel) { create(:option_set, name: "Multi", option_names: :multilevel) }

        it "should display all_levels_required only if multilevel select one and required" do
          visit(edit_qing_path)
          expect_field_visibility("all_levels_required", :hidden)

          check("Required")
          expect_field_visibility("all_levels_required", :hidden)

          select("Select One", from: "Type")
          expect_field_visibility("all_levels_required", :hidden)

          select("Regular", from: "Option Set")
          expect_field_visibility("all_levels_required", :hidden)

          select("Multi", from: "Option Set")
          expect_field_visibility("all_levels_required", :read_only)
        end
      end
    end

    context "with live form" do
      let(:question_types) { %w[text text] }
      let(:form) { create(:form, :live, question_types: question_types) }

      it "should display all fields as not editable" do
        visit(edit_qing_path)
        expect_field_visibility("required", :read_only)
        expect_field_visibility("hidden", :read_only)
        expect_field_visibility("disabled", :read_only)
        expect_field_visibility("display_logic", :read_only, field_type: "select")
        expect_field_visibility("skip_logic", :read_only, field_type: "select")
      end

      context "with media question" do
        let(:question_types) { %w[text image] }

        it "should display all fields as not editable" do
          visit(edit_qing_path)
          expect_field_visibility("required", :read_only)
          expect_field_visibility("hidden", :read_only)
          expect_field_visibility("disabled", :read_only)
          expect_field_visibility("display_logic", :read_only, field_type: "select")
          expect_field_visibility("skip_logic", :read_only, field_type: "select")
        end
      end
    end
  end

  context "for unpublished std copy" do
    let(:standard_form) { create(:form, :standard, question_types: %w[text text]) }
    let(:copied_form) { standard_form.replicate(mode: :to_mission, dest_mission: get_mission) }
    let(:qing) { copied_form.questionings.last }

    it "should display all fields as editable" do
      visit(edit_qing_path)
      expect_field_visibility("required", :editable)
      expect_field_visibility("hidden", :editable)
      expect_field_visibility("disabled", :editable)
      expect_field_visibility("display_logic", :editable, field_type: "select")
      expect_field_visibility("skip_logic", :editable, field_type: "select")
    end
  end

  # `value` can be one of :hidden, :read_only, :editable
  def expect_field_visibility(field, value, **options)
    case value
    when :hidden then expect_visible(field, false) && expect_editable(field, false, options)
    when :read_only then expect_visible(field, true) && expect_editable(field, false, options)
    when :editable then expect_visible(field, true) && expect_editable(field, true, options)
    else raise ArgumentError
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
