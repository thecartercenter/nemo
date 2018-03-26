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

    let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} #{form.c[4].code}" }
    let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} #{form.c[0].code} is equal to 5" }
    let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} #{form.c[1].code} is equal to 10" }

    include_examples :logic do
      subject { form }
    end

    before do
      form.c[2].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "any_met",
        conditions_attributes: [
          {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
          {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
        ])
    end

    context "with existing skip rule" do
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
        select "Skip to the end of the form", from: "questioning[skip_rules_attributes][0][destination]"
        select "if all of these conditions are met", from: "questioning[skip_rules_attributes][0][skip_if]"
        select "1. IntegerQ1", from: "questioning[skip_rules_attributes][0][conditions_attributes][0][ref_qing_id]"
        fill_in "questioning[skip_rules_attributes][0][conditions_attributes][0][value]", with: 3

        # second skip rule
        select "Skip to the end of the form", from: "questioning[skip_rules_attributes][0][destination]"
        select "if any of these conditions are met", from: "questioning[skip_rules_attributes][0][skip_if]"
        select "3. IntegerQ3", from: "questioning[skip_rules_attributes][0][conditions_attributes][0][ref_qing_id]"
        fill_in "questioning[skip_rules_attributes][0][conditions_attributes][0][value]", with: 2


        # delete first skip rule
        within(".skip-rule-remove.rule-1") do
          page.find(".fa.fa-close").click
        end

        click_on "Save"

        expect(page).to have_content("Add Questions")
        expect(page).to have_content("Jay's Question")

        # revisit questioning
        visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[5].id}/edit")

        expect(page).to have_select("questioning[skip_rules_attributes][0][conditions_attributes][0][ref_qing_id]",
          selected: "3. IntegerQ3")
      end
    end
  end
end
