# frozen_string_literal: true

require "rails_helper"

feature "report generation", js: true do
  let!(:user) { create(:user) }
  let!(:form) { create(:form, question_types: %w[integer select_one text]) }
  let!(:response1) { create(:response, form: form, answer_values: %w[1 Cat Foo]) }
  let!(:response2) { create(:response, form: form, answer_values: %w[2 Dog Bar]) }
  let!(:response3) { create(:response, form: form, answer_values: %w[3 Dog Blah]) }
  let!(:qs) { form.questions }

  # Flakey test due to JS in create modal
  describe "list report" do
    scenario "should work" do
      # Generate list report with two cols.
      login(user)
      visit(new_report_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
      choose("List Report")
      click_button("Next")

      # Advance though next two screens with expects to ensure we don't go too fast.
      expect(page).to have_content("New Report: Options")
      click_button("Next")
      expect(page).to have_content("New Report: Select Forms")
      click_button("Next")
      expect(page).to have_content("New Report: Fields")

      click_link("Add Column")
      all("select.field")[0].select("Submitter Name")
      click_link("Add Column")
      all("select.field")[1].select(qs[0].code)
      run_report_and_wait
      expect_cols(2)
      expect(page).to have_content(qs[0].name)

      # Remove last col and add new one.)
      edit_report
      2.times { click_button("Next") }
      expect(page).to have_selector(".report-form .fa-trash-o")
      all(".report-form a.remove").last.click
      click_link("Add Column")
      all("select.field")[1].select(qs[1].code)
      run_report_and_wait
      expect_cols(2)
      expect(page).not_to have_content(qs[0].name)
      expect(page).to have_content(qs[1].name)
    end
  end

  describe "standard form report" do
    let(:tag1) { build(:tag) }
    let(:tag2) { build(:tag) }
    let(:tag3) { build(:tag) }
    let!(:standard_report) { create(:standard_form_report, form: form, group_by_tag: true) }

    before do
      qs[0].tags = [tag1]
      qs[1].tags = [tag2]
      qs[2].tags = [tag3, tag1]
    end

    scenario "should work" do
      login(user)
      visit(reports_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
      click_link(standard_report.name)

      expect(page).to have_content("Cat")
      expect(page).to have_content("Dog")
      expect(page).to have_content("33.3% (1)")
      expect(page).to have_selector(".tag-header", count: 4)
      expect(page).to have_selector(".tag-header", text: /questions tagged #{tag1.name}/i)
      expect(page).to have_selector(".tag-header", text: /untagged questions/i)

      # Check that group by tag is checked
      edit_report
      expect(find("#group_by_tag")).to be_checked
    end
  end

  def run_report_and_wait
    click_button("Run")
    expect(page).to have_selector(".report-body tr td")
  end

  def edit_report
    click_link("Edit")
    expect(page).to have_selector(".modal-title", text: /Edit Report: Options/)
  end

  def expect_cols(num)
    expect(all(".report-body tr:first-child th").size).to eq(num)
  end
end
