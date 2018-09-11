# frozen_string_literal: true

require "rails_helper"

feature "report generation", js: true do
  let!(:user) { create(:user) }
  let!(:form) { create(:form, question_types: %w[integer select_one text]) }
  let!(:response1) { create(:response, form: form, answer_values: %w[1 Cat Foo]) }
  let!(:response2) { create(:response, form: form, answer_values: %w[2 Dog Bar]) }
  let!(:response3) { create(:response, form: form, answer_values: %w[3 Dog Blah]) }
  let!(:qs) { form.questions }

  describe "list report" do
    scenario "should work" do
      # Generate list report with two cols.
      login(user)
      visit(new_report_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
      choose("List Report")
      click_button("Next")

      # Advance though modal with expects to ensure buttons are visible
      expect(page).to have_content("New Report: Options")
      click_button("Next")
      expect(page).to have_content("New Report: Select Forms")
      expect(page).to have_content("Next")

      click_button("Next")
      expect(page).to have_content("New Report: Fields")

      click_link("Add Column")
      all("select.field")[0].select("Submitter Name")
      click_link("Add Column")
      all("select.field")[1].select(qs[0].code)
      run_report_and_wait
      expect_cols(2)

      # Remove last col and add new one.)
      edit_report
      2.times { click_button("Next") }
      expect(page).to have_selector(".report_form .fa-trash-o")
      all(".report_form a.remove").last.click
      click_link("Add Column")
      all("select.field")[1].select(qs[1].code)
      run_report_and_wait
      expect_cols(2)
    end
  end

  describe "standard form report" do
    let(:tag1) { build(:tag) }
    let(:tag2) { build(:tag) }
    let(:tag3) { build(:tag) }

    scenario "should work" do
      qs[0].tags = [tag1]
      qs[1].tags = [tag2]
      qs[2].tags = [tag3, tag1]

      login(user)

      # Generate standard form report
      visit(new_report_path(mode: "m", mission_name: get_mission.compact_name, locale: "en"))
      choose("Standard Form Report")
      click_button("Next")
      fill_in("report_title", with: "SFR Test")

      # Group questions by tag
      check("group_by_tag")
      select(form.name, from: "form_id")

      run_report_and_wait

      expect(page).to have_selector(".tag-header", count: 4)
      expect(page).to have_selector(".tag-header", text: /questions tagged #{tag1.name}/i)
      expect(page).to have_selector(".tag-header", text: /untagged questions/i)

      # Check that group by tag is checked
      visit reports_path(mode: "m", mission_name: get_mission.compact_name, locale: "en")
      click_link "SFR Test"
      edit_report
      expect(find("#group_by_tag")).to be_checked
    end
  end

  def run_report_and_wait
    click_button("Run")
    expect(page).to have_selector(".report_body tr td")
  end

  def edit_report
    click_link("Edit Report")
    expect(page).to have_selector(".modal-title", text: /Edit Report: Options/)
  end

  def expect_cols(num)
    expect(all(".report_body tr:first-child th").size).to eq num
  end
end
