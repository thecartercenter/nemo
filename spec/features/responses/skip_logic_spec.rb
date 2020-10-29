# frozen_string_literal: true

require "rails_helper"

feature "response form skip logic", js: true do
  include_context "response tree"

  let(:user) { create(:user) }
  let(:qings) { form.questionings }

  before do
    login(user)
  end

  describe "with skip rules" do
    let(:form) do
      create(:form, :live, question_types:
        ["text", "text", "text", "text", {repeating: {items: ["text"]}}])
    end

    scenario "skip to end of form" do
      # Skip to end of form if [1] is equal to B
      create(
        :skip_rule,
        source_item: qings[1],
        destination: "end",
        conditions_attributes: [{left_qing_id: qings[1].id, op: "eq", value: "B"}]
      )
      visit_new_response_page
      visible = [[0], [1], [2], [3]]
      fill_and_expect_visible([0], "A", visible)
      fill_and_expect_visible([1], "A", visible)
      fill_and_expect_visible([1], "B", visible - [[2], [3]])
      fill_and_expect_visible([1], "C", visible)
    end

    scenario "skip over a required question to a later questioning" do
      qings[1].update!(required: true)

      # Skip from [0] to [2] if [0] is not equal to A
      create(
        :skip_rule,
        source_item: qings[0],
        destination: "item",
        dest_item_id: qings[2].id,
        conditions_attributes: [{left_qing_id: qings[0].id, op: "neq", value: "A"}]
      )

      visit_new_response_page
      select2(user.name, from: "response_user_id")
      visible = [[0], [1], [2], [3]]
      expect_visible(visible - [[1]])
      fill_and_expect_visible([0], "A", visible)
      fill_and_expect_visible([0], "B", visible - [[1]])
      fill_and_expect_visible([2], "C", visible - [[1]])
      fill_and_expect_visible([0], "A", visible)

      # Save this one so we know it saves ok if required question skipped.
      click_button("Save")
      expect(page).to have_content("created successfully")
    end

    scenario "two skip rules and skip rule and condition have same ref qing, skip triggered first" do
      # Display [3] if [0] is not equal to B
      # Skip from [1] to [3] if [0] is A
      # Skip from [0] to [2] if [0] is Skip2
      qings[3].display_conditions << Condition.new(
        left_qing_id: qings[0].id,
        op: "neq",
        value: "B"
      )
      qings[3].save!
      create(
        :skip_rule,
        source_item: qings[1],
        destination: "item",
        dest_item_id: qings[3].id,
        conditions_attributes: [{left_qing_id: qings[0].id, op: "eq", value: "A"}]
      )
      create(
        :skip_rule,
        source_item: qings[0],
        destination: "item",
        dest_item_id: qings[2].id,
        conditions_attributes: [{left_qing_id: qings[0].id, op: "eq", value: "Skip2"}]
      )
      visit_new_response_page
      visible = [[0], [1], [2], [3]]
      expect_visible(visible)
      fill_and_expect_visible([0], "D", visible)
      fill_and_expect_visible([1], "C", visible)
      fill_and_expect_visible([2], "B", visible)
      fill_and_expect_visible([0], "A", visible - [[2]])
      fill_and_expect_visible([3], "Z", visible - [[2]])
      fill_and_expect_visible([0], "G", visible)
      fill_and_expect_visible([0], "B", visible - [[3]])
      fill_and_expect_visible([0], "Skip2", visible - [[1]])
      fill_and_expect_visible([0], "Z", visible)
    end

    scenario "two skip rules, skip rule and condition have same ref qing, display cond triggered first" do
      # Display [3] if [0] is not equal to B
      # Skip from [1] to [3] if [0] is A
      # Skip from [0] to [2] if [0] is Skip2
      qings[3].display_conditions << Condition.new(
        left_qing_id: qings[0].id,
        op: "neq",
        value: "B"
      )
      qings[3].save!
      create(
        :skip_rule,
        source_item: qings[1],
        destination: "item",
        dest_item_id: qings[3].id,
        conditions_attributes: [{left_qing_id: qings[0].id, op: "eq", value: "A"}]
      )
      create(
        :skip_rule,
        source_item: qings[0],
        destination: "item",
        dest_item_id: qings[2].id,
        conditions_attributes: [{left_qing_id: qings[0].id, op: "eq", value: "Skip2"}]
      )
      visit_new_response_page
      visible = [[0], [1], [2], [3]]
      expect_visible(visible)
      fill_and_expect_visible([0], "Z", visible)
      fill_and_expect_visible([0], "B", visible - [[3]])
      fill_and_expect_visible([1], "C", visible - [[3]])
      fill_and_expect_visible([2], "A", visible - [[3]])
      fill_and_expect_visible([0], "Z", visible)
      fill_and_expect_visible([0], "Skip2", visible - [[1]])
      fill_and_expect_visible([0], "Z", visible)
    end
  end

  describe "skip rules with conditions on repeat groups" do
    # Skip to end of form if [1] is equal to B.
    # Display repeat group if [2] is "ShowRepeat"
    let(:form) do
      create(:form, :live, question_types:
        ["text", "text", "text", "text", {repeating: {items: ["text"]}}])
    end

    scenario "trigger display condition on form with skip rule" do
      create(
        :skip_rule,
        source_item: qings[1],
        destination: "end",
        conditions_attributes: [{left_qing_id: qings[1].id, op: "eq", value: "B"}]
      )
      form.c[4].update!(
        display_if: "all_met",
        display_conditions_attributes: [{left_qing_id: qings[2].id, op: "eq", value: "ShowRepeat"}]
      )
      visit_new_response_page
      visible = [[0], [1], [2], [3], [4, 0, 0]]
      fill_and_expect_visible([0], "No change", visible - [[4, 0, 0]])
      fill_and_expect_visible([1], "No change", visible - [[4, 0, 0]])
      fill_and_expect_visible([1], "B", visible - [[2], [3], [4, 0, 0]])
      fill_and_expect_visible([1], "Undo Skip", visible - [[4, 0, 0]])
      fill_and_expect_visible([2], "ShowRepeat", visible)
      fill_and_expect_visible([4, 0, 0], "Fill Repeat", visible)
      fill_and_expect_visible([1], "B", visible - [[2], [3], [4, 0, 0]])
      fill_and_expect_visible([1], "Undo Skip", visible)
      fill_and_expect_visible([2], "HideRepeat", visible - [[4, 0, 0]])
    end
  end
end
