# frozen_string_literal: true

require "spec_helper"

feature "skip rule form", js: true do
  let!(:user) { create(:user) }
  let!(:form) do
    create(:form,
      name: "Foo",
      question_types: %w[integer multilevel_select_one select_one integer])
  end

  before do
    login(user)
  end

  context "with existing skip rule" do
    let!(:form) do
      create(:form,
        name: "Foo",
        question_types: %w[integer integer integer integer integer])
    end
    let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} #{form.c[4].code}" }
    let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} #{form.c[0].code} is equal to 5" }
    let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} #{form.c[1].code} is equal to 10" }

    scenario "read-only mode" do
      form.c[2].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "any_met",
                                   conditions_attributes: [
                                     {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
                                     {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
                                   ])
      expected = "Skip to #{dest_qing_str} if any of these conditions are met "\
        "#{first_cond_str} "\
        "#{second_cond_str}"
      visit("/en/m/#{form.mission.compact_name}/questionings/#{form.c[2].id}")
      expect(page).to have_content(expected)
    end
  end
end
