# frozen_string_literal: true

require "spec_helper"

feature "skip rule form", js: true do
  let!(:user) { create(:user) }

  before do
    login(user)
  end

  context do
    let(:form) do
      create(:form,
        name: "Foo",
        question_types: %w[integer integer integer integer integer])
    end

    let(:dest_qing_str) { dest_qing_str }
    let(:first_cond_str) { first_cond_str }
    let(:second_cond_str) { second_cond_str }

    include_examples :form_logic do
      subject { form }
    end

    before do
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

    context "with existing skip rule" do
      let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} #{form.c[4].code}" }
      let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} #{form.c[0].code} is equal to 5" }
      let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} #{form.c[1].code} is equal to 10" }

      scenario "read-only mode" do
        expected = "Skip to #{dest_qing_str} if any of these conditions are met "\
        "#{first_cond_str} "\
        "#{second_cond_str}"
        visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[2].id}")
        expect(page).to have_content(expected)
      end
    end

    context "new questioning" do
      scenario "add multiple skip rules" do
        visit edit_form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name)
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
        visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[5].id}/edit")

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

      scenario do
        visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[2].id}/edit")

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

        rule_2 = "Skip to #{dest_qing_str} if all of these conditions are met "\
        "#{first_cond_str} "\
        "#{second_cond_str}"

        visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[2].id}")
        expect(page).to have_content(rule_2)
      end
    end
  end
end
