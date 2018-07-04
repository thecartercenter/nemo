# frozen_string_literal: true

require "rails_helper"

feature "skip logic form fields", js: true do
  let!(:user) { create(:admin) }
  let(:form) do
    create(:form,
      name: "Foo",
      question_types: %w[integer integer integer integer integer],
      is_standard: is_standard)
  end
  let(:dest_qing_str) { dest_qing_str }
  let(:first_cond_str) { first_cond_str }
  let(:second_cond_str) { second_cond_str }

  include_context "form design conditional logic"

  before do
    login(user)
    form.c[2].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "any_met",
                                 conditions_attributes: [
                                   {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
                                   {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
                                 ])
    form.c[2].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "all_met",
                                 conditions_attributes: [
                                   {ref_qing_id: form.c[0].id, op: "eq", value: "25"},
                                   {ref_qing_id: form.c[1].id, op: "neq", value: "20"}
                                 ])
  end

  shared_examples_for "correct behavior" do
    context "with existing skip rule" do
      let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} #{form.c[4].code}" }
      let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} #{form.c[0].code} is equal to 5" }
      let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} #{form.c[1].code} is equal to 10" }

      scenario "read-only mode" do
        expected = "Skip to #{dest_qing_str} if any of these conditions are met "\
          "#{first_cond_str} "\
          "#{second_cond_str}"
        visit("#{url_prefix}/questionings/#{form.c[2].id}")
        expect(page).to have_content(expected)
      end
    end

    context "new questioning" do
      scenario "add multiple skip rules" do
        visit("#{url_prefix}/forms/#{form.id}/edit")
        click_on "Add Questions"

        fill_in("Code", with: "QueueMe")
        select("Text", from: "Type")
        fill_in("Title (English)", with: "Jay's Question")

        # Add multiple skip rules to new questioning, deleting one
        select "After this question, skip ...", from: "Skip Logic"

        # first skip rule
        within(all(".skip-rule")[0]) do
          find('select[name*="\\[skip_if\\]"]').select("if any of these conditions are met")

          within(all(".condition-fields")[0]) do
            select_question(form.c[0].code)
            select_operator("< less than")
            fill_in_value("25")
          end
        end

        click_add_rule

        # second skip rule
        within(all(".skip-rule")[1]) do
          find('select[name*="\\[skip_if\\]"]').select("if any of these conditions are met")
          within(all(".condition-fields")[0]) do
            select_question(form.c[0].code)
            select_operator("< less than")
            fill_in_value("20")
          end
        end

        # delete first skip rule
        within(".rule-1") do
          click_delete_link
        end

        click_on "Save"

        expect(page).to have_content("Add Questions")
        expect(page).to have_content("Jay's Question")

        # revisit questioning
        visit("#{url_prefix}/questionings/#{form.c[5].id}/edit")

        # data is persisted
        expect(all(".condition-fields").size).to eq 1

        within(all(".condition-fields")[0]) do
          expect_selected_question(form.c[0])
          expect_selected_operator("< less than")
          expect_filled_in_value("20")
        end
      end
    end

    context "existing questioning" do
      let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} #{form.c[4].code}" }
      let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} #{form.c[0].code} is less than 1000" }
      let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} #{form.c[1].code} is equal to 10" }

      scenario "rules are updated correctly" do
        visit("#{url_prefix}/questionings/#{form.c[2].id}/edit")

        # edit first rule
        within(all(".skip-rule")[0]) do
          find('select[name*="\\[skip_if\\]"]').select("if all of these conditions are met")
          within(all(".condition-fields")[0]) do
            select_question(form.c[0].code)
            select_operator("< less than")
            fill_in_value("1000")
          end
        end

        # delete second rule
        within(".rule-2") do
          click_delete_link
        end

        click_on "Save"

        rule2 = "Skip to #{dest_qing_str} if all of these conditions are met "\
          "#{first_cond_str} "\
          "#{second_cond_str}"

        visit("#{url_prefix}/questionings/#{form.c[2].id}")
        expect(page).to have_content(rule2)
      end

      scenario "delete existing condition if rule is set to always" do
        visit("#{url_prefix}/questionings/#{form.c[2].id}/edit")

        # confirm that data is available on visit
        expect(page).to have_css(".condition-fields")
        expect(page).to have_content("= equals")
        expect(page).to have_select("questioning_skip_logic",
          selected: "After this question, skip ...")

        # set skip rule to always
        within(all(".skip-rule")[0]) do
          find('select[name*="\\[skip_if\\]"]').select("in all cases")

          # condition fields are hidden for the first skip rule
          expect(all(".condition-fields").size).to eq 0
        end

        # condition fields still exist for the second skip rule
        within(all(".skip-rule")[1]) do
          expect(all(".condition-fields").size).to eq 2
        end
      end

      scenario "delete existing rule if question is set to not skip" do
        visit("#{url_prefix}/questionings/#{form.c[2].id}/edit")

        # confirm that data is available on visit
        expect(page).to have_css(".condition-fields")
        expect(page).to have_content("= equals")
        expect(page).to have_select("questioning_skip_logic",
          selected: "After this question, skip ...")

        # set skip to always
        select "After this question, go to the next question", from: "questioning_skip_logic"

        expect(page).not_to have_css(".skip-rule-set")
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
end
