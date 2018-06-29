# frozen_string_literal: true

require "rails_helper"

feature "display logic form fields", js: true do
  let!(:user) { create(:admin) }
  let!(:form) do
    create(:form,
      name: "Foo",
      question_types: %w[integer multilevel_select_one select_one integer],
      is_standard: is_standard)
  end

  include_context "form design conditional logic"

  shared_examples_for "correct behavior" do
    before do
      login(user)
      visit("#{url_prefix}/forms/#{form.id}/edit")
      expect(page).to have_content("Edit Form")
    end

    scenario "add a new question with multiple conditions" do
      when_new_question_is_created
      with_multiple_conditions
      visit("#{url_prefix}/questionings/#{form.c[4].id}/edit")
      then_conditions_are_persisted
    end

    context "with existing conditions" do
      before do
        add_existing_conditions
      end

      scenario "edit conditions on an existing question" do
        all("a.action_link.edit")[3].click

        when_conditions_are_deleted
        and_then_edited

        # View and check saved properly.
        visit("#{url_prefix}/questionings/#{form.c[3].id}/edit")
        then_changes_are_persisted

        # Display always removes condition fields
        visit("#{url_prefix}/questionings/#{form.c[3].id}/edit")
        select("Always display this question", from: "Display Logic")
        click_on "Save"
        visit("#{url_prefix}/questionings/#{form.c[3].id}/edit")
        expect(page).to have_select("questioning_display_logic",
          selected: "Always display this question")
        expect(page).not_to have_css(".condition-fields")
      end

      scenario "read-only mode" do
        visit("#{url_prefix}/questionings/#{form.c[3].id}")
        expect(page).to have_content("Display this question if any of these conditions are met "\
        "Question #1 #{form.c[0].code} is greater than or equal to 64 "\
        "Question #3 #{form.c[2].code} is equal to \"Cat\"")
      end
    end
  end

  context "regular mode" do
    let(:is_standard) { false }
    let(:url_prefix) { "/en/m/#{form.mission.compact_name}" }
    include_examples "correct behavior"
  end

  context "admin mode" do
    let(:is_standard) { true }
    let(:url_prefix) { "/en/admin" }
    include_examples "correct behavior"
  end

  def when_new_question_is_created
    click_link("Add Questions")
    fill_in("Code", with: "NewQ")
    select("Text", from: "Type")
    fill_in("Title (English)", with: "New Question")

    expect(page).not_to have_css(".condition-fields")
    expect(page).not_to have_content("Add Condition")
  end

  def with_multiple_conditions
    select("Display this question if all of these conditions are met", from: "Display Logic")

    # First condition
    within(all(".condition-fields")[0]) do
      select_question(form.c[0].code)
      select_operator("< less than")
      fill_in_value("5")
    end

    # Second condition (deleted)
    click_add_condition
    within(all(".condition-fields")[1]) do
      select_question(form.c[0].code)
      select_operator("> greater than")
      fill_in_value("0")
      click_delete_link
    end

    # Third condition
    click_add_condition
    within(all(".condition-fields")[1]) do
      select_question(form.c[1].code)
      select_operator("= equals")
      select_values("Plant", "Oak")
    end

    # Accidentally change display_if selector, should not delete selections.
    select("Always display this question", from: "Display Logic")
    expect(page).not_to have_css(".condition-fields")
    select("Display this question if all of these conditions are met", from: "Display Logic")

    click_button("Save")
    expect(page).to have_content("Question created successfully.")
  end

  def then_conditions_are_persisted
    expect(all(".condition-fields").size).to eq 2

    within(all(".condition-fields")[0]) do
      expect_selected_question(form.c[0])
      expect_selected_operator("< less than")
      expect_filled_in_value("5")
    end

    within(all(".condition-fields")[1]) do
      expect_selected_question(form.c[1])
      expect_selected_operator("= equals")
      expect_selected_values("Plant", "Oak")
    end
  end

  def add_existing_conditions
    form.c[3].update_attributes!(display_if: "any_met", display_conditions_attributes: [
      {ref_qing_id: form.c[0].id, op: "geq", value: "64"},
      {ref_qing_id: form.c[2].id, op: "eq", option_node_id: form.c[2].option_set.c[0].id}
    ])
  end

  def when_conditions_are_deleted
    # Delete existing condition
    within(all(".condition-fields")[0]) do
      click_delete_link
      expect(page).not_to have_css(".condition-fields", visible: true)
    end
  end

  def and_then_edited
    # Edit existing condition
    within(all(".condition-fields")[0]) do
      select_question(form.c[1].code)
      select_operator("= equals")
      select_values("Plant", "Oak")

      # Change mind!
      select_question(form.c[0].code)
      select_operator("= equals")
      fill_in_value("8")
    end

    # Add new condition
    click_add_condition
    within(all(".condition-fields")[1]) do
      select_question(form.c[0].code)
      select_operator("< less than")
      fill_in_value("25")

      # Change mind!
      select_question(form.c[1].code)
      select_operator("= equals")
      select_values("Plant", "Oak")

      # Change again!
      select_question(form.c[2].code)
      select_operator("= equals")
      select_values("Cat")
    end

    # Add another new condition and delete
    click_add_condition
    within(all(".condition-fields")[2]) do
      select_question(form.c[0].code)
      select_operator("≤ less than or equal to")
      fill_in_value("99")
      click_delete_link
    end

    click_button("Save")
    expect(page).to have_content("Question updated successfully.")
  end

  def then_changes_are_persisted
    expect(page).to have_select("questioning_display_logic",
      selected: "Display this question if any of these conditions are met")
    expect(all(".condition-fields").size).to eq 2

    within(all(".condition-fields")[0]) do
      expect_selected_question(form.c[0])
      expect_selected_operator("= equals")
      expect_filled_in_value("8")
    end

    within(all(".condition-fields")[1]) do
      expect_selected_question(form.c[2])
      expect_selected_operator("= equals")
      expect_selected_values("Cat")
    end
  end
end
