require "spec_helper"

feature "skip rules in responses", js: true do
  let(:user) { create(:user) }
  let(:form) { create(:form) }

  before do
    qings # Ensure these get created before we visit page.
    login(user)
  end

  describe "with skip rules" do
    let(:group) { create(:qing_group, form: form) }
    let(:rpt_group) { create(:qing_group, form: form, repeatable: true) }
    let!(:qings) do
      {}.tap do |qings|
        qings[:text1] = create_questioning("text", form)

        qings[:text2] = create_questioning("text", form)

        qings[:text3] = create_questioning("text", form)

        qings[:text4] = create_questioning("text", form)
      end
    end

    scenario "skip to end of form" do
      # Skip to end of form if text2 is equal to B
      create(
        :skip_rule,
        source_item: qings[:text2],
        destination: "end",
        conditions_attributes: [{ref_qing_id: qings[:text2].id, op: "eq", value: "B"}]
      )

      visit_new_response_page
      visible = %i[text1 text2 text3 text4]
      fill_and_expect_visible(:text1, "A", visible)
      fill_and_expect_visible(:text2, "A", visible)
      fill_and_expect_visible(:text2, "B", visible - %i[text3 text4])
      fill_and_expect_visible(:text2, "C", visible)
    end

    scenario "skip to a later questioning" do
      # Skip from text1 to text3 if text1 is not equal to A
      create(
        :skip_rule,
        source_item: qings[:text1],
        destination: "item",
        dest_item_id: qings[:text3].id,
        conditions_attributes: [{ref_qing_id: qings[:text1].id, op: "neq", value: "A"}]
      )

      visit_new_response_page
      visible = %i[text1 text2 text3 text4]
      expect_visible(visible - %i[text2])
      fill_and_expect_visible(:text1, "A", visible)
      fill_and_expect_visible(:text1, "B", visible - %i[text2])
      fill_and_expect_visible(:text3, "C", visible - %i[text2])
      fill_and_expect_visible(:text1, "A", visible)
    end

    scenario "two skip rules and skip rule and condition have same ref qing, skip triggered first" do
      # Display text4 if text1 is not equal to B
      # Skip from text2 to text4 if text1 is A
      # Skip from text1 to text3 if text1 is Skip2

      qings[:text4].display_conditions << Condition.new(
        {ref_qing_id: qings[:text1].id, op: "neq", value: "B"}
      )
      qings[:text4].save!

      create(
        :skip_rule,
        source_item: qings[:text2],
        destination: "item",
        dest_item_id: qings[:text4].id,
        conditions_attributes: [{ref_qing_id: qings[:text1].id, op: "eq", value: "A"}]
      )

      create(
        :skip_rule,
        source_item: qings[:text1],
        destination: "item",
        dest_item_id: qings[:text3].id,
        conditions_attributes: [{ref_qing_id: qings[:text1].id, op: "eq", value: "Skip2"}]
      )

      visit_new_response_page
      visible = %i[text1 text2 text3 text4]
      expect_visible(visible)
      fill_and_expect_visible(:text1, "D", visible)
      fill_and_expect_visible(:text2, "C", visible)
      fill_and_expect_visible(:text3, "B", visible)
      fill_and_expect_visible(:text1, "A", visible - %i[text3])
      fill_and_expect_visible(:text4, "Z", visible - %i[text3])
      fill_and_expect_visible(:text1, "G", visible)
      fill_and_expect_visible(:text1, "B", visible - %i[text4])
      fill_and_expect_visible(:text1, "Skip2", visible - %i[text2])
      fill_and_expect_visible(:text1, "Z", visible)
    end

    scenario "two skip rules, skip rule and condition have same ref qing, display cond triggered first" do
      # Display text4 if text1 is not equal to B
      # Skip from text2 to text4 if text1 is A
      # Skip from text1 to text3 if text1 is Skip2

      qings[:text4].display_conditions << Condition.new(
        {ref_qing_id: qings[:text1].id, op: "neq", value: "B"}
      )
      qings[:text4].save!

      create(
        :skip_rule,
        source_item: qings[:text2],
        destination: "item",
        dest_item_id: qings[:text4].id,
        conditions_attributes: [{ref_qing_id: qings[:text1].id, op: "eq", value: "A"}]
      )

      create(
        :skip_rule,
        source_item: qings[:text1],
        destination: "item",
        dest_item_id: qings[:text3].id,
        conditions_attributes: [{ref_qing_id: qings[:text1].id, op: "eq", value: "Skip2"}]
      )

      visit_new_response_page
      visible = %i[text1 text2 text3 text4]
      expect_visible(visible)
      fill_and_expect_visible(:text1, "Z", visible)
      fill_and_expect_visible(:text1, "B", visible - %i[text4])
      fill_and_expect_visible(:text2, "C", visible - %i[text4])
      fill_and_expect_visible(:text3, "A", visible - %i[text4])
      fill_and_expect_visible(:text1, "Z", visible)
      fill_and_expect_visible(:text1, "Skip2", visible - %i[text2])
      fill_and_expect_visible(:text1, "Z", visible)
    end
  end

  describe "skip rules with conditions on repeat groups" do
    # Skip to end of form if text2 is equal to B.
    # Display repeat group if text3 is "ShowRepeat"

    let(:rpt_group) { create(
      :qing_group,
      form: form,
      repeatable: true
      # Display condition added below
    ) }

    let!(:qings) do
      {}.tap do |qings|
        qings[:text1] = create_questioning("text", form)

        qings[:text2] = create_questioning("text", form)

        qings[:text3] = create_questioning("text", form)

        qings[:text4] = create_questioning("text", form)

        qings[:rptq1] = create_questioning("text", form, parent: rpt_group)
      end
    end

    scenario "trigger display condition on form with skip rule" do
      create(
        :skip_rule,
        source_item: qings[:text2],
        destination: "end",
        conditions_attributes: [{ref_qing_id: qings[:text2].id, op: "eq", value: "B"}]
      )

      rpt_group.update_attributes!(
        display_if: "all_met",
        display_conditions_attributes: [{
          ref_qing_id: qings[:text3].id,
          op: "eq",
          value: "ShowRepeat"
        }])

      visit_new_response_page
      visible = %i[text1 text2 text3 text4 rptq1]
      fill_and_expect_visible(:text1, "No change", visible - %i[rptq1])
      fill_and_expect_visible(:text2, "No change", visible - %i[rptq1])
      fill_and_expect_visible(:text2, "B", visible - %i[text3 text4 rptq1])
      fill_and_expect_visible(:text2, "Undo Skip", visible - %i[rptq1])
      fill_and_expect_visible(:text3, "ShowRepeat", visible)
      fill_and_expect_visible(:rptq1, "Fill Repeat", visible)
      fill_and_expect_visible(:text2, "B", visible - %i[text3 text4 rptq1])
      fill_and_expect_visible(:text2, "Undo Skip", visible)
      fill_and_expect_visible(:text3, "HideRepeat", visible - %i[rptq1])
    end
  end

  def visit_new_response_page
    visit(new_response_path(
      locale: "en",
      mode: "m",
      mission_name: get_mission.compact_name,
      form_id: form.id
    ))
  end

  def fill_and_expect_visible(field, value, visible)
    fill_answer(field: field, value: value)
    expect_visible(visible)
  end

  def fill_answer(field:, value:)
    qing = qings[field.is_a?(Symbol) ? field : field[0]]
    inst = field.is_a?(Symbol) ? 1 : field[1][:inst]
    idx = "#{qing.id}_#{inst}"
    id = "response_answers_attributes_#{idx}_value"
    within(selector_for(qing, inst)) do
      #only text
      fill_in(id, with: value)
    end
  end

  # visible_fields should be an array of symbols or pairs of form [symbol, {inst: X}] where X is
  # the instance descriptor we should be looking in. If a plain symbol is passed, we assume instance 1.
  def expect_visible(visible_fields)
    # We transform visible_fields to the form {Questioning => [X, Y], ...} where X, Y are instance descriptors.
    visible_fields = {}.tap do |list|
      visible_fields.each do |item|
        if item.is_a?(Symbol)
          qing = qings[item]
          inst = 1
        else
          qing = qings[item[0]]
          inst = item[1][:inst]
        end
        list[qing] ||= []
        list[qing] << inst
      end
    end

    form.questionings.each do |qing|
      # Get instance count for parent instance.
      inst_count = if qing.depth == 1
        1
      else
        # TODO: When we add support for nested groups to this spec, we will need to refine this selector
        # to distinguish between different sets of subinstances within a parent repeat group's instances.
        page.all(%(div.qing-group-instance[data-group-id="#{qing.parent_id}"])).size
      end

      # For each instance, check visibility.
      # TODO: When we add support for nested groups to this spec, we will have to
      # respect the full instance descriptor, not just a single number.
      (1..inst_count).each do |inst|
        if (visible_fields[qing] || []).include?(inst)
          expect(find(selector_for(qing, inst))).to be_visible
        else
          expect(find(selector_for(qing, inst), visible: false)).not_to be_visible
        end
      end
    end
  end

  # Gets a CSS selector for the answer_field div described by the given qing and instance descriptor.
  def selector_for(qing, inst)
    %(div.answer_field[data-qing-id="#{qing.id}"][data-inst-num="#{inst}")
  end
end
