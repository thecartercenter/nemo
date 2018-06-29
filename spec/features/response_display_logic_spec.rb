# frozen_string_literal: true

require "rails_helper"

feature "response form display logic", js: true do
  include_context "response form conditional logic"

  let(:user) { create(:user) }
  let(:form) { create(:form) }

  before do
    qings # Ensure these get created before we visit page.
    login(user)
  end

  describe "different question types" do
    let(:year) { Time.zone.now.year - 2 }
    let(:group) { create(:qing_group, form: form) }
    let(:rpt_group) { create(:qing_group, form: form, repeatable: true) }
    let!(:qings) do
      {}.tap do |qings|
        qings[:long_text] = create_questioning("long_text", form)

        qings[:text1] = create_questioning("text", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:long_text].id, op: "eq", value: "foo"}
        ])

        qings[:integer] = create_questioning("integer", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:text1].id, op: "neq", value: "bar"}
        ])

        qings[:counter] = create_questioning("counter", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:integer].id, op: "gt", value: "10"}
        ])

        qings[:text2] = create_questioning("text", form)

        qings[:decimal] = create_questioning("decimal", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:counter].id, op: "gt", value: "5"}
        ])

        qings[:select_one] = create_questioning("select_one", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:decimal].id, op: "eq", value: "21.72"}
        ])

        oset = qings[:select_one].option_set
        qings[:mlev_sel_one] = create_questioning("multilevel_select_one", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:select_one].id, op: "eq", option_node_id: oset.node("Dog").id}
        ])

        oset = qings[:mlev_sel_one].option_set
        qings[:geo_sel_one] = create_questioning("geo_multilevel_select_one", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:mlev_sel_one].id, op: "eq", option_node_id: oset.node("Plant", "Tulip").id}
        ])

        oset = qings[:geo_sel_one].option_set
        qings[:select_multiple] = create_questioning("select_multiple", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:geo_sel_one].id, op: "eq", option_node_id: oset.node("Canada").id}
        ])

        oset = qings[:select_multiple].option_set
        qings[:datetime] = create_questioning("datetime", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:select_multiple].id, op: "inc", option_node_id: oset.node("Cat").id}
        ])

        qings[:date] = create_questioning("date", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:datetime].id, op: "lt", value: "#{year}-01-01 5:00:21"}
        ])

        qings[:time] = create_questioning("time", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:date].id, op: "eq", value: "#{year}-03-22"}
        ])

        qings[:text3] = create_questioning("text", form, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:time].id, op: "geq", value: "3:00pm"}
        ])

        qings[:grp1] = create_questioning("text", form, parent: group)

        qings[:rpt1] = create_questioning("text", form, parent: rpt_group, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:text3].id, op: "eq", value: "baz"} # References top level Q
        ])

        qings[:rpt2] = create_questioning("text", form, parent: rpt_group, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:rpt1].id, op: "eq", value: "qux"} # References same group Q
        ])

        qings[:rpt3] = create_questioning("text", form, parent: rpt_group, display_if: "all_met",
          display_conditions_attributes: [
            {ref_qing_id: qings[:grp1].id, op: "eq", value: "nix"} # References Q from sibling group
        ])
      end
    end

    scenario "various conditions on questionings should work" do
      visit_new_response_page
      visible = [:long_text, :text2, :grp1]
      fill_and_expect_visible(:long_text, "fo", visible)

      # integer also becomes available here because it depends on text1 not being bar,
      # which it isn't at first, because "" != "bar"
      fill_and_expect_visible(:long_text, "foo", visible << :text1 << :integer)

      fill_and_expect_visible(:text1, "bar", visible - [:integer])
      fill_and_expect_visible(:text1, "barz", visible << :integer)
      fill_and_expect_visible(:integer, "10", visible)
      fill_and_expect_visible(:integer, "11", visible << :counter)
      fill_and_expect_visible(:counter, "5", visible)
      fill_and_expect_visible(:counter, "6", visible << :decimal)
      fill_and_expect_visible(:decimal, "21.7", visible)
      fill_and_expect_visible(:decimal, "21.72", visible << :select_one)
      fill_and_expect_visible(:select_one, "Cat", visible)
      fill_and_expect_visible(:select_one, "Dog", visible << :mlev_sel_one)
      fill_and_expect_visible(:mlev_sel_one, ["Plant"], visible)
      fill_and_expect_visible(:mlev_sel_one, ["Plant", "Oak"], visible)
      fill_and_expect_visible(:mlev_sel_one, ["Plant", "Tulip"], visible << :geo_sel_one)
      fill_and_expect_visible(:geo_sel_one, ["Ghana"], visible)
      fill_and_expect_visible(:geo_sel_one, ["Canada"], visible << :select_multiple)
      fill_and_expect_visible(:geo_sel_one, ["Canada", "Ottawa"], visible)
      fill_and_expect_visible(:select_multiple, ["Dog"], visible)
      fill_and_expect_visible(:select_multiple, ["Dog", "Cat"], visible << :datetime)
      fill_and_expect_visible(:datetime, "#{year}-01-01 5:00:21", visible)
      fill_and_expect_visible(:datetime, "#{year}-01-01 5:00:20", visible << :date)
      fill_and_expect_visible(:date, "#{year}-03-21", visible)
      fill_and_expect_visible(:date, "#{year}-03-22", visible << :time)
      fill_and_expect_visible(:time, "6:00:00", visible)
      fill_and_expect_visible(:time, "15:00:00", visible << :text3)
      fill_and_expect_visible(:text3, "baz", visible << [:rpt1, inst: 1])
      fill_and_expect_visible([:rpt1, inst: 1], "qux", visible << [:rpt2, inst: 1])
      fill_and_expect_visible(:grp1, "nix", visible << [:rpt3, inst: 1])

      find("a.add-instance").click

      # rpt1 and rpt3 depend on q's outside of the repeat group so their visibility should match instance 1
      expect_visible(visible << [:rpt1, inst: 2] << [:rpt3, inst: 2])

      fill_and_expect_visible([:rpt1, inst: 2], "qux", visible << [:rpt2, inst: 2])

      # Changing value in grp1 should make *both* rpt3s disappear.
      fill_and_expect_visible(:grp1, "pix", visible -= [[:rpt3, inst: 1], [:rpt3, inst: 2]])
    end
  end

  describe "display_if logic" do
    let!(:qings) do
      {}.tap do |qings|
        qings[:q1] = create_questioning("integer", form)
        qings[:q2] = create_questioning("integer", form)
        qings[:q3] = create_questioning(
          "integer",
          form,
          display_if: display_if,
          display_conditions_attributes: [
            {ref_qing_id: qings[:q1].id, op: "gt", value: "10"},
            {ref_qing_id: qings[:q2].id, op: "gt", value: "20"}
          ]
        )
      end
    end

    describe "condition on qing group" do
      let!(:group) { create(:qing_group, form: form) }
      let!(:qings) do
        {}.tap do |qings|
          qings[:test] = create_questioning("text", form)
          qings[:grp_q1] = create_questioning("text", form, parent: group)
        end
      end

      before do
        group.update_attributes!(display_if: "all_met",
          display_conditions_attributes: [{
            ref_qing_id: qings[:test].id,
            op: "eq",
            value: "foo"
          }])
      end

      scenario "should hide group members until conditions met" do
        visit_new_response_page
        visible = [:test]
        fill_and_expect_visible(:test, "no", visible)
        fill_and_expect_visible(:test, "foo", visible << :grp_q1)
      end
    end

    describe "all_met" do
      let(:display_if) { "all_met" }

      scenario "conditions should all need to be met" do
        visit_new_response_page
        visible = [:q1, :q2]
        fill_and_expect_visible(:q1, "10", visible)
        fill_and_expect_visible(:q2, "20", visible)

        # This satisfies the first condition but not the second, so q3 should not show yet.
        fill_and_expect_visible(:q1, "11", visible)

        # This satisfies the second condition but not the first, so q3 should still not show.
        fill_and_expect_visible(:q1, "10", visible)
        fill_and_expect_visible(:q2, "21", visible)

        # NOW it should show!
        fill_and_expect_visible(:q1, "11", visible << :q3)
      end
    end

    describe "any_met" do
      let(:display_if) { "any_met" }

      scenario "only one condition should need to be met" do
        visit_new_response_page
        visible = [:q1, :q2]

        fill_and_expect_visible(:q1, "10", visible)
        fill_and_expect_visible(:q2, "20", visible)

        # Satisfy one, expect visible
        fill_and_expect_visible(:q1, "11", visible + [:q3])

        # Satisfy both, expect visible
        fill_and_expect_visible(:q2, "21", visible + [:q3])

        # Unsatisfy first one, expect still visible
        fill_and_expect_visible(:q1, "10", visible + [:q3])

        # Unsatisfy second one, expect not visible
        fill_and_expect_visible(:q2, "20", visible)
      end
    end
  end
end
