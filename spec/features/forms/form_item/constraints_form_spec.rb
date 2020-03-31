# frozen_string_literal: true

require "rails_helper"

feature "constraints form fields", js: true do
  let!(:user) { create(:admin) }
  let(:standard) { false }
  let(:traits) { standard ? [:standard] : [] }
  let(:form) do
    create(:form, *traits, name: "Foo", question_types: %w[integer integer integer integer integer])
  end

  include_context "form design conditional logic"

  before do
    login(user)
    form.c[2].constraints.create!(accept_if: "any_met",
                                  conditions_attributes: [
                                    {left_qing_id: form.c[0].id, op: "eq", value: "5"},
                                    {left_qing_id: form.c[1].id, op: "eq", value: "10"}
                                  ],
                                  rejection_msg_translations: {
                                    en: "Custom rejection message"
                                  })
    form.c[2].constraints.create!(accept_if: "all_met",
                                  conditions_attributes: [
                                    {left_qing_id: form.c[0].id, op: "eq", value: "25"},
                                    {left_qing_id: form.c[1].id, op: "neq", value: "20"}
                                  ])
  end

  shared_examples_for "correct behavior" do
    context "with existing constraint" do
      let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} [#{form.c[4].code}]" }
      let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} [#{form.c[0].code}] is equal to 5" }
      let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} [#{form.c[1].code}] is equal to 10" }

      scenario "read-only mode" do
        expected = "Valid only if any of these conditions are met\n#{first_cond_str}\n#{second_cond_str}"
        visit("#{url_prefix}/questionings/#{form.c[2].id}")
        expect(page).to have_content(expected)
      end
    end

    context "new questioning" do
      scenario "add multiple constraints" do
        visit("#{url_prefix}/forms/#{form.id}/edit")
        click_on("Add Questions")

        fill_in("Code", with: "QueueMe")
        select("Text", from: "Type")
        fill_in("Title (English)", with: "Jay's Question")

        # Add multiple constraints to new questioning, deleting one
        select("Only accept an answer if ...", from: "Constraints")

        # first constraint
        within(all(".rule")[0]) do
          within(all(".condition-fields")[0]) do
            select_left_qing(form.c[0].code)
            select_operator("< less than")
            fill_in_value("25")
          end
        end

        click_add_rule

        # second constraint
        within(all(".rule")[1]) do
          within(all(".condition-fields")[0]) do
            select_left_qing(form.c[0].code)
            select_operator("< less than")
            fill_in_value("20")
          end
          click_link("Add Rejection Message")
        end
        wait_modal_to_be_visible
        within(".modal-dialog") do
          within(".modal-body") do
            fill_in("English", with: "Custom Rejection Message")
          end
        end
        click_modal_save_button

        # delete first constraint
        within(".constraint-1") do
          click_delete_link
        end

        click_on("Save")

        expect(page).to have_content("Add Questions")
        expect(page).to have_content("Jay's Question")

        # revisit questioning
        visit("#{url_prefix}/questionings/#{form.c[5].id}/edit")

        # data is persisted
        expect(all(".condition-fields").size).to eq(1)
        within(all(".condition-fields")[0]) do
          expect_selected_left_qing(form.c[0])
          expect_selected_operator("< less than")
          expect_filled_in_value("20")
        end
        click_link("Edit Rejection Message")
        wait_modal_to_be_visible
        expect(page).to have_field("English", with: "Custom Rejection Message")
      end
    end

    context "existing questioning" do
      let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} [#{form.c[4].code}]" }
      let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} [#{form.c[0].code}] is less than 1000" }
      let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} [#{form.c[1].code}] is equal to 10" }

      scenario "rules are updated correctly" do
        visit("#{url_prefix}/questionings/#{form.c[2].id}/edit")

        # edit first rule
        within(all(".rule")[0]) do
          choose(option: "all_met")
          within(all(".condition-fields")[0]) do
            select_left_qing(form.c[0].code)
            select_operator("< less than")
            fill_in_value("1000")
          end
          click_link("Edit Rejection Message")
        end
        wait_modal_to_be_visible
        within(".modal-dialog") do
          within(".modal-body") do
            fill_in("English", with: "Custom Rejection Message")
          end
        end
        click_modal_save_button

        # delete second rule
        within(".constraint-2") do
          click_delete_link
        end

        click_on("Save")

        rule2 = "Valid only if all of these conditions are met\n#{first_cond_str}\n#{second_cond_str}"
        visit("#{url_prefix}/questionings/#{form.c[2].id}")
        expect(page).to have_content(rule2)
      end

      scenario "delete existing rule if question is set to not skip" do
        visit("#{url_prefix}/questionings/#{form.c[2].id}/edit")

        # confirm that data is available on visit
        expect(page).to have_css(".condition-fields")
        expect(page).to have_content("= equals")
        expect(page).to have_select("questioning_constraints",
          selected: "Only accept an answer if ...")

        # set skip to always
        select("Accept any answer", from: "questioning_constraints")

        expect(page).not_to have_css(".rule-set")
      end
    end
  end

  def click_modal_save_button
    find(".modal-footer .btn-primary").click
    wait_modal_to_hide
  end

  context "regular mode" do
    let(:url_prefix) { "/en/m/#{form.mission.compact_name}" }
    include_examples "correct behavior"
  end

  context "admin mode" do
    let(:standard) { true }
    let(:url_prefix) { "/en/admin" }
    include_examples "correct behavior"
  end
end
