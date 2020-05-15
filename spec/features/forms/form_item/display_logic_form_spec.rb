# frozen_string_literal: true

require "rails_helper"

feature "display logic form fields", js: true do
  let!(:user) { create(:admin) }
  let(:standard) { false }
  let(:traits) { standard ? [:standard] : [] }
  let!(:form) do
    create(:form, *traits, name: "Foo",
                           question_types: %w[integer integer multilevel_select_one select_one integer])
  end

  include_context "form design conditional logic"

  before do
    login(user)
    visit("#{url_prefix}/forms/#{form.id}/edit")
    expect(page).to have_content("Edit Form")
  end

  shared_examples_for "correct behavior" do
    scenario "add a new question with multiple conditions" do
      click_link("Add Questions")
      fill_in("Code", with: "NewQ")
      select("Text", from: "Type")
      fill_in("Title (English)", with: "New Question")
      expect(page).not_to have_css(".condition-fields")
      expect(page).not_to have_content("Add Condition")

      # Create four conditions, deleting the second
      select("Display this question if all of these conditions are met", from: "Display Logic")
      within(all(".condition-fields")[0]) do
        select_left_qing(form.c[0].code)
        select_operator("< less than")
        fill_in_value("5")
      end
      click_add_condition
      within(all(".condition-fields")[1]) do
        select_left_qing(form.c[0].code)
        select_operator("> greater than")
        fill_in_value("0")
        click_remove_link
      end
      click_add_condition
      within(all(".condition-fields")[1]) do
        select_left_qing(form.c[2].code)
        select_operator("= equals")
        select_values("Plant", "Oak")
      end
      click_add_condition
      within(all(".condition-fields")[2]) do
        select_left_qing(form.c[0].code)
        select_operator("= equals")
        select_right_qing(form.c[1].code)
      end

      # Accidentally change display_if selector, should not delete selections.
      select("Always display this question", from: "Display Logic")
      expect(page).not_to have_css(".condition-fields")
      select("Display this question if all of these conditions are met", from: "Display Logic")
      click_button("Save")

      expect(page).to have_content("Question created successfully.")
      visit("#{url_prefix}/questionings/#{form.c[5].id}/edit")

      # Ensure all persisted
      expect(all(".condition-fields").size).to eq(3)
      within(all(".condition-fields")[0]) do
        expect_selected_left_qing(form.c[0])
        expect_selected_operator("< less than")
        expect_filled_in_value("5")
      end
      within(all(".condition-fields")[1]) do
        expect_selected_left_qing(form.c[2])
        expect_selected_operator("= equals")
        expect_selected_values("Plant", "Oak")
      end
      within(all(".condition-fields")[2]) do
        expect_selected_left_qing(form.c[0])
        expect_selected_operator("= equals")
        expect_selected_right_qing(form.c[1])
      end
    end

    context "with existing conditions" do
      before do
        form.c[4].update!(display_if: "any_met", display_conditions_attributes: [
          {left_qing_id: form.c[0].id, op: "geq", value: "64"},
          {left_qing_id: form.c[3].id, op: "eq", option_node_id: form.c[3].option_set.c[0].id},
          {left_qing_id: form.c[0].id, op: "eq",
           right_side_type: "qing", right_qing_id: form.c[1].id}
        ])
      end

      scenario "edit and delete conditions on an existing question" do
        all("a.action-link.action-link-edit")[4].click

        # Delete existing condition
        within(all(".condition-fields")[0]) do
          click_remove_link
          expect(page).not_to have_css(".condition-fields", visible: true)
        end

        # Edit existing condition
        within(all(".condition-fields")[0]) do
          select_left_qing(form.c[2].code)
          select_operator("= equals")
          select_values("Plant", "Oak")

          # Change mind!
          select_left_qing(form.c[0].code)
          select_operator("= equals")
          fill_in_value("8")
        end

        # Add new condition
        click_add_condition
        within(all(".condition-fields")[2]) do
          select_left_qing(form.c[0].code)
          select_operator("< less than")
          fill_in_value("25")

          # Change mind!
          select_left_qing(form.c[2].code)
          select_operator("= equals")
          select_values("Plant", "Oak")

          # Change again!
          select_left_qing(form.c[3].code)
          select_operator("= equals")
          select_values("Cat")
        end

        # Add another new condition and delete
        click_add_condition
        within(all(".condition-fields")[3]) do
          select_left_qing(form.c[0].code)
          select_operator("≤ less than or equal to")
          fill_in_value("99")
          click_remove_link
        end

        click_button("Save")
        expect(page).to have_content("Question updated successfully.")

        # View and check saved properly.
        visit("#{url_prefix}/questionings/#{form.c[4].id}/edit")
        expect(page).to have_select("questioning_display_logic",
          selected: "Display this question if any of these conditions are met")
        expect(all(".condition-fields").size).to eq(3)
        within(all(".condition-fields")[0]) do
          expect_selected_left_qing(form.c[0])
          expect_selected_operator("= equals")
          expect_filled_in_value("8")
        end
        within(all(".condition-fields")[1]) do
          expect_selected_left_qing(form.c[0])
          expect_selected_operator("= equals")
          expect_selected_right_qing(form.c[1])
        end
        within(all(".condition-fields")[2]) do
          expect_selected_left_qing(form.c[3])
          expect_selected_operator("= equals")
          expect_selected_values("Cat")
        end

        # Ensure that setting 'display always' removes condition fields
        visit("#{url_prefix}/questionings/#{form.c[4].id}/edit")
        select("Always display this question", from: "Display Logic")
        click_on("Save")
        visit("#{url_prefix}/questionings/#{form.c[4].id}/edit")
        expect(page).to have_select("questioning_display_logic",
          selected: "Always display this question")
        expect(page).not_to have_css(".condition-fields")
      end

      scenario "read-only mode" do
        # Happy path only--details of read only logic are in decorator.
        visit("#{url_prefix}/questionings/#{form.c[4].id}")
        expect(page).to have_content("is greater than or equal to 64")
      end
    end
  end

  context "regular mode" do
    let(:url_prefix) { "/en/m/#{form.mission.compact_name}" }
    include_examples "correct behavior"

    scenario "happy path for qing_group" do
      click_link("Add Group")
      fill_in("Name (English)", with: "Foo Group")
      select("Display this group if any", from: "qing_group_display_logic")
      within(all(".condition-fields")[0]) do
        select_left_qing(form.c[2].code)
        select_operator("= equals")
        select_values("Plant", "Oak")
      end
      within(".modal") { click_button("Save") }

      # Open it back up and check that the values were persisted.
      find("li.form-item-group").click
      within(".modal") do
        expect(page).to have_select("qing_group_display_logic",
          selected: "Display this group if any of these conditions are met")
        expect(page).to have_select("qing_group[display_conditions_attributes][0][option_node_ids][]",
          selected: "Oak")
      end
    end
  end

  context "admin mode" do
    let(:standard) { true }
    let(:url_prefix) { "/en/admin" }
    include_examples "correct behavior"
  end
end
