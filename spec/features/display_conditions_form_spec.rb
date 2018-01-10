require "spec_helper"

feature "conditions flow", js: true do
  let!(:user) { create(:user) }
  let!(:form) { create(:form, name: "Foo",
    question_types: %w(integer multilevel_select_one integer integer)) }

  before do
    login(user)
    visit(edit_form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))
    expect(page).to have_content("Edit Form")
  end

  scenario "add a new question with multiple conditions" do
    click_link("Add Questions")
    fill_in("Code", with: "NewQ")
    select("Text", from: "Type")
    fill_in("Title (English)", with: "New Question")

    expect(page).not_to have_css(".condition-fields")
    expect(page).not_to have_content("Add Condition")

    select("Display this question if all of these conditions are met", from: "Display Logic")

    # First condition
    within(all(".condition-fields")[0]) do
      select_question_and_wait_to_populate_other_selects(form.c[0].code)
      select("is less than", from: "Comparison")
      fill_in("Value", with: "5")
    end

    # Second condition (deleted)
    click_on("Add Condition")
    within(all(".condition-fields")[1]) do
      select_question_and_wait_to_populate_other_selects(form.c[0].code)
      select("is greater than", from: "Comparison")
      fill_in("Value", with: "0")
      find(".fa-trash-o").click
      expect(page).not_to have_css(".condition-fields", visible: true)
    end

    # Third condition
    click_on("Add Condition")
    within(all(".condition-fields")[2]) do
      select_question_and_wait_to_populate_other_selects(form.c[1].code)
      select("is equal to", from: "Comparison")
      select("Plant", from: "Kingdom")
      select("Oak", from: "Species")
    end

    click_button("Save")

    visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[4].id}")
    expect(page).to have_content("Display this question if all of these conditions are met "\
      "Question #1 #{form.c[0].code} is less than 5 "\
      "Question #2 #{form.c[1].code} Species is equal to \"Oak\"")
    expect(page).not_to have_content("greater than")
  end

  def select_question_and_wait_to_populate_other_selects(question_code)
    select(question_code, from: "Question")
    wait_for_ajax
  end
end
