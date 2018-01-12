require "spec_helper"

feature "display conditions form", js: true do
  let!(:user) { create(:user) }
  let!(:form) { create(:form, name: "Foo",
    question_types: %w(integer multilevel_select_one select_one integer)) }

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
      select_question(form.c[0].code)
      select_operator("is less than")
      fill_in_value("5")
    end

    # Second condition (deleted)
    click_on("Add Condition")
    within(all(".condition-fields")[1]) do
      select_question(form.c[0].code)
      select_operator("is greater than")
      fill_in_value("0")
      click_delete_link
    end

    # Third condition
    click_on("Add Condition")
    within(all(".condition-fields")[1]) do
      select_question(form.c[1].code)
      select_operator("is equal to")
      select_values("Plant", "Oak")
    end

    # Accidentally change display_if selector, should not delete selections.
    select("Always display this question", from: "Display Logic")
    expect(page).not_to have_css(".condition-fields")
    select("Display this question if all of these conditions are met", from: "Display Logic")

    click_button("Save")
    expect(page).to have_content("Question created successfully.")

    visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[4].id}/edit")
    expect(all(".condition-fields").size).to eq 2

    within(all(".condition-fields")[0]) do
      expect_selected_question(form.c[0])
      expect_selected_operator("is less than")
      expect_filled_in_value("5")
    end

    within(all(".condition-fields")[1]) do
      expect_selected_question(form.c[1])
      expect_selected_operator("is equal to")
      expect_selected_values("Plant", "Oak")
    end
  end

  context "with existing conditions" do
    before do
      form.c[3].update_attributes!(display_if: "any_met", display_conditions_attributes: [
        {ref_qing_id: form.c[0].id, op: "geq", value: "64"},
        {ref_qing_id: form.c[2].id, op: "eq", option_node_id: form.c[2].option_set.c[0].id}
      ])
    end

    scenario "edit conditions on an existing question" do
      all("a.action_link.edit")[3].click

      # Delete existing condition
      within(all(".condition-fields")[0]) do
        click_delete_link
        expect(page).not_to have_css(".condition-fields", visible: true)
      end

      # Edit existing condition
      within(all(".condition-fields")[0]) do
        select_question(form.c[1].code)
        select_operator("is equal to")
        select_values("Plant", "Oak")

        # Change mind!
        select_question(form.c[0].code)
        select_operator("is equal to")
        fill_in_value("8")
      end

      # Add new condition
      click_on("Add Condition")
      within(all(".condition-fields")[1]) do
        select_question(form.c[0].code)
        select_operator("is less than")
        fill_in_value("25")

        # Change mind!
        select_question(form.c[1].code)
        select_operator("is equal to")
        select_values("Plant", "Oak")

        # Change again!
        select_question(form.c[2].code)
        select_operator("is equal to")
        select_values("Cat")
      end

      # Add another new condition and delete
      click_on("Add Condition")
      within(all(".condition-fields")[2]) do
        select_question(form.c[0].code)
        select_operator("is less than or equal to")
        fill_in_value("99")
        click_delete_link
      end

      click_button("Save")
      expect(page).to have_content("Question updated successfully.")

      # View and check saved properly.
      visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[3].id}/edit")
      expect(page).to have_select("questioning_display_logic",
        selected: "Display this question if any of these conditions are met")
      expect(all(".condition-fields").size).to eq 2

      within(all(".condition-fields")[0]) do
        expect_selected_question(form.c[0])
        expect_selected_operator("is equal to")
        expect_filled_in_value("8")
      end

      within(all(".condition-fields")[1]) do
        expect_selected_question(form.c[2])
        expect_selected_operator("is equal to")
        expect_selected_values("Cat")
      end
    end

    scenario "read-only mode" do
      visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[3].id}")
      expect(page).to have_content("Display this question if any of these conditions are met "\
        "Question #1 #{form.c[0].code} is greater than or equal to 64 "\
        "Question #3 #{form.c[2].code} is equal to \"Cat\"")
    end
  end

  def select_question(code)
    find('select[name*="\\[ref_qing_id\\]"]').select(code)
    wait_for_ajax # Changing the question triggers an ajax call (for now)
  end

  def expect_selected_question(qing)
    select = find('select[name*="\\[ref_qing_id\\]"]')
    expect(page).to have_select(select[:name], selected: "#{qing.full_dotted_rank}. #{qing.code}")
  end

  def select_operator(op)
    find('select[name*="\\[op\\]"]').select(op)
  end

  def expect_selected_operator(op)
    select = find('select[name*="\\[op\\]"]')
    expect(page).to have_select(select[:name], selected: op)
  end

  def select_values(*values)
    selects = all('select[name*="\\[option_node_ids\\]"]')
    values.each_with_index do |value, i|
      selects[i].select(value)
    end
  end

  def expect_selected_values(*values)
    selects = all('select[name*="\\[option_node_ids\\]"]')
    expect(selects.size).to eq values.size
    selects.each_with_index do |select, i|
      expect(page).to have_select(select[:name], selected: values[i])
    end
  end

  def fill_in_value(value)
    find('input[name*="\\[value\\]"]').set(value)
  end

  def expect_filled_in_value(value)
    input = find('input[name*="\\[value\\]"]')
    expect(page).to have_field(input[:name], with: value)
  end

  def click_delete_link
    find(".fa-close").click
  end
end
