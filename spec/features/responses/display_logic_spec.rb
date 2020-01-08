# frozen_string_literal: true

require "rails_helper"

feature "response form display logic", js: true do
  include_context "response tree"

  before { login(create(:user)) }

  let(:qings) { form.root_group.c }

  describe "different question types" do
    let(:year) { Time.zone.now.year - 2 }

    let!(:form) do
      create(:form, :live,
        question_types: [
          "long_text",                 # 0
          "text",                      # 1
          "integer",                   # 2
          "counter",                   # 3
          "text",                      # 4
          "decimal",                   # 5
          "select_one",                # 6
          "multilevel_select_one",     # 7
          "geo_multilevel_select_one", # 8
          "select_multiple",           # 9
          "datetime",                  # 10
          "date",                      # 11
          "time",                      # 12
          "text",                      # 13
          %w[text],                    # 14.0
          {
            repeating: {
              items: [
                "text",                # 15.0
                "text",                # 15.1
                "text",                # 15.2
                {
                  repeating: {
                    items: %w[integer] # 15.3.0
                  }
                }
              ]
            }
          }
        ])
    end

    before do
      # setup conditions

      qings[1].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[0].id, op: "eq", value: "foo"}
        ]
      )

      qings[2].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[1].id, op: "neq", value: "bar"}
        ]
      )

      qings[3].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[2].id, op: "gt", value: "10"},
          # Include a right_side_is_qing condition, which should be ignored for now
          {left_qing_id: qings[1].id, op: "eq", right_qing_id: qings[0].id}
        ]
      )

      qings[5].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[3].id, op: "gt", value: "5"}
        ]
      )

      qings[6].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[5].id, op: "eq", value: "21.72"}
        ]
      )

      oset = qings[6].option_set
      qings[7].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[6].id, op: "eq", option_node_id: oset.node("Dog").id}
        ]
      )

      oset = qings[7].option_set
      qings[8].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[7].id, op: "eq", option_node_id: oset.node("Plant", "Tulip").id}
        ]
      )

      oset = qings[8].option_set
      qings[9].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[8].id, op: "eq", option_node_id: oset.node("Canada").id}
        ]
      )

      oset = qings[9].option_set
      qings[10].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[9].id, op: "inc", option_node_id: oset.node("Cat").id}
        ]
      )

      qings[11].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[10].id, op: "lt", value: "#{year}-01-01 5:00:21"}
        ]
      )

      qings[12].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[11].id, op: "eq", value: "#{year}-03-22"}
        ]
      )

      qings[13].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[12].id, op: "geq", value: "3:00pm"}
        ]
      )

      qings[15].c[0].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[13].id, op: "eq", value: "baz"} # References top level Q
        ]
      )

      qings[15].c[1].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[15].c[0].id, op: "eq", value: "qux"} # References same group Q
        ]
      )

      qings[15].c[2].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[14].c[0].id, op: "eq", value: "nix"} # References Q from sibling group
        ]
      )

      qings[15].c[3].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[14].c[0].id, op: "geq", value: 5}
        ]
      )
    end

    scenario "various conditions on questionings should work" do
      visit_new_response_page

      visible = [[0], [4], [14]]

      fill_and_expect_visible([0], "fo", visible)

      # integer also becomes available here because it depends on text1 not being bar,
      # which it isn't at first, because "" != "bar"
      fill_and_expect_visible([0], "foo", visible << [1] << [2])

      fill_and_expect_visible([1], "bar", visible - [[2]])
      fill_and_expect_visible([1], "barz", visible << [2])
      fill_and_expect_visible([2], "10", visible)
      fill_and_expect_visible([2], "11", visible << [3])
      fill_and_expect_visible([3], "5", visible)
      fill_and_expect_visible([3], "6", visible << [4])
      fill_and_expect_visible([5], "21.7", visible)
      fill_and_expect_visible([5], "21.72", visible << [6])
      fill_and_expect_visible([6], "Cat", visible)
      fill_and_expect_visible([6], "Dog", visible << [7])
      fill_and_expect_visible([7], %w[Plant], visible)
      fill_and_expect_visible([7], %w[Plant Oak], visible)
      fill_and_expect_visible([7], %w[Plant Tulip], visible << [8])
      fill_and_expect_visible([8], %w[Ghana], visible)
      fill_and_expect_visible([8], %w[Canada], visible << [8])
      fill_and_expect_visible([8], %w[Canada Ottawa], visible)
      fill_and_expect_visible([9], %w[Dog], visible)
      fill_and_expect_visible([9], %w[Dog Cat], visible << [10])
      fill_and_expect_visible([10], "#{year}-01-01 5:00:21", visible)
      fill_and_expect_visible([10], "#{year}-01-01 5:00:20", visible << [11])
      fill_and_expect_visible([11], "#{year}-03-21", visible)
      fill_and_expect_visible([11], "#{year}-03-22", visible << [12])
      fill_and_expect_visible([12], "6:00:00", visible)
      fill_and_expect_visible([12], "15:00:00", visible << [13])
      fill_and_expect_visible([13], "baz", visible << [15, 0])
      fill_and_expect_visible([15, 0, 0], "qux", visible << [15, 0, 1])
      fill_and_expect_visible([14, 0], "nix", visible << [15, 0, 2])
      visible -= [[15, 0, 1]]
      fill_and_expect_visible([15, 0, 0], "4", visible)
      fill_and_expect_visible([15, 0, 0], "5", visible << [15, 0, 3])

      all(:css, "a.add-repeat").last.click # top-level repeat

      # same things visible after adding repeat
      expect_visible(visible)

      # item from second instance not visible since it depends on sibling value
      expect_visible(visible - [[15, 1, 3]])

      # update sibling and it becomes visible
      fill_and_expect_visible([15, 1, 0], "5", visible << [15, 1, 3])

      # these depend on q's outside of the repeat group so their visibility should match the first instance
      expect_visible(visible << [15, 1, 0] << [15, 1, 2])

      fill_and_expect_visible([15, 1, 0], "qux", visible << [15, 1, 1])

      # changing value should make *both* repeats disappear
      fill_and_expect_visible([14, 0], "pix", visible - [[15, 0, 2], [15, 1, 2]])
    end
  end

  describe "display_if logic" do
    let!(:form) do
      create(:form, :live,
        question_types: [
          "integer", # 0
          "integer", # 1
          "integer", # 2
          "text",    # 3
          %w[text]   # 4.0
        ])
    end

    describe "condition on qing group" do
      before do
        qings[4].update!(
          display_if: "all_met",
          display_conditions_attributes: [{
            left_qing_id: qings[3].id,
            op: "eq",
            value: "foo"
          }]
        )
      end

      scenario "should hide group members until conditions met" do
        visit_new_response_page
        visible = [[3]]
        fill_and_expect_visible([3], "no", visible)
        fill_and_expect_visible([3], "foo", visible << [4, 0])
      end
    end

    context "condition on qing" do
      before do
        qings[2].update!(
          display_if: display_if,
          display_conditions_attributes: [
            {left_qing_id: qings[0].id, op: "gt", value: "10"},
            {left_qing_id: qings[1].id, op: "gt", value: "20"}
          ]
        )
      end

      describe "all_met" do
        let(:display_if) { "all_met" }

        scenario "conditions should all need to be met" do
          visit_new_response_page
          visible = [[0], [1]]
          fill_and_expect_visible([0], "10", visible)
          fill_and_expect_visible([1], "20", visible)

          # This satisfies the first condition but not the second, so q3 should not show yet.
          fill_and_expect_visible([0], "11", visible)

          # This satisfies the second condition but not the first, so q3 should still not show.
          fill_and_expect_visible([0], "10", visible)
          fill_and_expect_visible([1], "21", visible)

          # NOW it should show!
          fill_and_expect_visible([0], "11", visible << [2])
        end
      end

      describe "any_met" do
        let(:display_if) { "any_met" }

        scenario "only one condition should need to be met" do
          visit_new_response_page
          visible = [[0], [1]]

          fill_and_expect_visible([0], "10", visible)
          fill_and_expect_visible([1], "20", visible)

          # Satisfy one, expect visible
          fill_and_expect_visible([0], "11", visible + [[2]])

          # Satisfy both, expect visible
          fill_and_expect_visible([1], "21", visible + [[2]])

          # Unsatisfy first one, expect still visible
          fill_and_expect_visible([0], "10", visible + [[2]])

          # Unsatisfy second one, expect not visible
          fill_and_expect_visible([1], "20", visible)
        end
      end
    end
  end
end
