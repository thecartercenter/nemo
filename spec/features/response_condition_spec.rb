require "spec_helper"

feature "conditions in responses", js: true do
  let(:user) { create(:user) }
  let!(:form) { create(:form) }
  let(:group) { create(:qing_group, form: form) }
  let(:rpt_group) { create(:qing_group, form: form, repeatable: true) }
  let!(:questionings) do
    {
      long_text: create_questioning("long_text", form),
      text1: create_questioning("text", form),
      integer: create_questioning("integer", form),
      counter: create_questioning("counter", form),
      text2: create_questioning("text", form),
      decimal: create_questioning("decimal", form),
      select_one: create_questioning("select_one", form),
      multilevel_select_one: create_questioning("multilevel_select_one", form),
      geo_multilevel_select_one: create_questioning("geo_multilevel_select_one", form),
      select_multiple: create_questioning("select_multiple", form),
      datetime: create_questioning("datetime", form),
      date: create_questioning("date", form),
      time: create_questioning("time", form),
      text3: create_questioning("text", form),
      grp1: create_questioning("text", form, group),
      rpt1: create_questioning("text", form, rpt_group),
      rpt2: create_questioning("text", form, rpt_group),
      rpt3: create_questioning("text", form, rpt_group)
    }
  end
  let!(:so_option_set) { questionings[:select_one].option_set }
  let!(:ml_option_set) { questionings[:multilevel_select_one].option_set }
  let!(:geo_option_set) { questionings[:geo_multilevel_select_one].option_set }
  let!(:multi_option_set) { questionings[:select_multiple].option_set }
  let!(:conditions) do
    {
      text1_if_long_text: questionings[:text1].create_condition(
        ref_qing: questionings[:long_text], op: "eq", value: "foo"),
      integer_if_text1: questionings[:integer].create_condition(
        ref_qing: questionings[:text1], op: "neq", value: "bar"),
      counter_if_integer: questionings[:counter].create_condition(
        ref_qing: questionings[:integer], op: "gt", value: "10"),
      decimal_if_counter: questionings[:decimal].create_condition(
        ref_qing: questionings[:counter], op: "gt", value: "5"),
      select_one_if_decimal: questionings[:select_one].create_condition(
        ref_qing: questionings[:decimal], op: "eq", value: "21.72"),
      ml_select_one_if_select_one: questionings[:multilevel_select_one].create_condition(
        ref_qing: questionings[:select_one],
        op: "eq",
        option_node: so_option_set.children.detect { |c| c.option_name == "Dog" }),
      geo_select_one_if_ml_select_one: questionings[:geo_multilevel_select_one].create_condition(
        ref_qing: questionings[:multilevel_select_one],
        op: "eq",
        option_node: ml_option_set.children.
          detect { |c| c.option_name == "Plant" }.children.
          detect { |c| c.option_name == "Tulip" }),
      select_multiple_if_geo_select_one: questionings[:select_multiple].create_condition(
        ref_qing: questionings[:geo_multilevel_select_one],
        op: "eq",
        option_node: geo_option_set.children.detect { |c| c.option_name == "Canada" }),
      datetime_if_select_multiple: questionings[:datetime].create_condition(
        ref_qing: questionings[:select_multiple],
        op: "inc",
        option_node: multi_option_set.children.detect { |c| c.option_name == "Cat" }),
      date_if_datetime: questionings[:date].create_condition(
        ref_qing: questionings[:datetime], op: "lt", value: "#{year}-01-01 5:00:21"),
      time_if_date: questionings[:time].create_condition(
        ref_qing: questionings[:date], op: "eq", value: "#{year}-03-22"),
      text3_if_time: questionings[:text3].create_condition(
        ref_qing: questionings[:time], op: "geq", value: "3:00pm"),
      rpt1_if_text3: questionings[:rpt1].create_condition( # References top level Q
        ref_qing: questionings[:text3], op: "eq", value: "baz"),
      rpt2_if_rpt1: questionings[:rpt2].create_condition( # References same group Q
        ref_qing: questionings[:rpt1], op: "eq", value: "qux"),
      rpt3_if_grp1: questionings[:rpt3].create_condition( # References Q from sibling group
        ref_qing: questionings[:grp1], op: "eq", value: "nix")
    }
  end
  let(:year) { Time.now.year - 2 }

  scenario "should work" do
    login(user)
    visit(new_response_path(locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id))
    expect(page).to have_content("New Response")

    visible = [:long_text, :text2]

    fill_answer_and_expect_visible(
      field: :long_text, value: "fo", visible: visible)

    fill_answer_and_expect_visible(
      field: :long_text, value: "foo", visible: visible << :text1)

    fill_answer_and_expect_visible(
      field: :text1, value: "bar", visible: visible)

    fill_answer_and_expect_visible(
      field: :text1, value: "barz", visible: visible << :integer)

    fill_answer_and_expect_visible(
      field: :integer, value: "10", visible: visible)

    fill_answer_and_expect_visible(
      field: :integer, value: "11", visible: visible << :counter)

    fill_answer_and_expect_visible(
      field: :counter, value: "5", visible: visible)

    fill_answer_and_expect_visible(
      field: :counter, value: "6", visible: visible << :decimal)

    fill_answer_and_expect_visible(
      field: :decimal, value: "21.7", visible: visible)

    fill_answer_and_expect_visible(
      field: :decimal, value: "21.72", visible: visible << :select_one)

    fill_answer_and_expect_visible(
      field: :select_one, value: "Cat", visible: visible)

    fill_answer_and_expect_visible(
      field: :select_one, value: "Dog", visible: visible << :multilevel_select_one)

    fill_answer_and_expect_visible(
      field: :multilevel_select_one, value: ["Plant"], visible: visible)

    fill_answer_and_expect_visible(
      field: :multilevel_select_one, value: ["Plant", "Oak"], visible: visible)

    fill_answer_and_expect_visible(
      field: :multilevel_select_one,
      value: ["Plant", "Tulip"],
      visible: visible << :geo_multilevel_select_one)

    fill_answer_and_expect_visible(
      field: :geo_multilevel_select_one,
      value: ["Ghana"],
      visible: visible)

    fill_answer_and_expect_visible(
      field: :geo_multilevel_select_one,
      value: ["Canada"],
      visible: visible << :select_multiple)

    fill_answer_and_expect_visible(
      field: :geo_multilevel_select_one,
      value: ["Canada", "Ottawa"],
      visible: visible)

    fill_answer_and_expect_visible(
      field: :select_multiple, value: ["Dog"], visible: visible)

    fill_answer_and_expect_visible(
      field: :select_multiple, value: ["Dog", "Cat"], visible: visible << :datetime)

    fill_answer_and_expect_visible(
      field: :datetime, value: "#{year}-01-01 5:00:21", visible: visible)

    fill_answer_and_expect_visible(
      field: :datetime, value: "#{year}-01-01 5:00:20", visible: visible << :date)

    fill_answer_and_expect_visible(
      field: :date, value: "#{year}-03-21", visible: visible)

    fill_answer_and_expect_visible(
      field: :date, value: "#{year}-03-22", visible: visible << :time)

    fill_answer_and_expect_visible(
      field: :time, value: "6:00:00", visible: visible)

    fill_answer_and_expect_visible(
      field: :time, value: "15:00:00", visible: visible << :text3)

    fill_answer_and_expect_visible(
      field: :text3, value: "baz", visible: visible << [:rpt1, inst: 1])

    fill_answer_and_expect_visible(
      field: [:rpt1, inst: 1], value: "qux", visible: visible << [:rpt2, inst: 1])

    fill_answer_and_expect_visible(
      field: :grp1, value: "nix", visible: visible << [:rpt3, inst: 1])

    find("a.add-instance").click

    # rpt1 and rpt3 depend on q's outside of the repeat group so their visibility should match instance 1
    expect_visible(visible << [:rpt1, inst: 2] << [:rpt3, inst: 2])

    fill_answer_and_expect_visible(
      field: [:rpt1, inst: 2], value: "qux", visible: visible << [:rpt2, inst: 2])

    # Changing value in grp1 should make *both* rpt3s disappear.
    fill_answer_and_expect_visible(
      field: :grp1, value: "pix", visible: visible -= [[:rpt3, inst: 1], [:rpt3, inst: 2]])
  end

  def fill_answer_and_expect_visible(field:, value:, visible:)
    fill_answer(field: field, value: value)
    expect_visible(visible)
  end

  def fill_answer(field:, value:)
    qing = questionings[field.is_a?(Symbol) ? field : field[0]]
    inst = field.is_a?(Symbol) ? 1 : field[1][:inst]
    idx = "#{qing.id}_#{inst}"
    id = "response_answers_attributes_#{idx}_value"
    within(selector_for(qing, inst)) do
      case qing.qtype_name
      when "long_text"
        fill_in_ckeditor(id, with: value)
      when "select_one"
        if value.is_a?(Array)
          value.each_with_index do |o,i|
            id = "response_answers_attributes_#{idx}_#{i}_option_node_id"
            find("#response_answers_attributes_#{idx}_#{i}_option_node_id option", text: o)
            select(o, from: id)
          end
        else
          select(value, from: "response_answers_attributes_#{idx}_option_node_id")
        end
      when "select_multiple"
        qing.options.each_with_index do |o,i|
          id = "response_answers_attributes_#{idx}_choices_attributes_#{i}_checked"
          value.include?(o.name) ? check(id) : uncheck(id)
        end
      when "datetime", "date", "time"
        t = Time.parse(value)
        prefix = "response_answers_attributes_#{idx}_#{qing.qtype_name}_value"
        unless qing.qtype_name == "time"
          select(t.strftime("%Y"), from: "#{prefix}_1i")
          select(t.strftime("%B"), from: "#{prefix}_2i")
          select(t.day.to_s, from: "#{prefix}_3i")
        end
        unless qing.qtype_name == "date"
          select(t.strftime("%H"), from: "#{prefix}_4i")
          select(t.strftime("%M"), from: "#{prefix}_5i")
          select(t.strftime("%S"), from: "#{prefix}_6i")
        end
      else
        fill_in(id, with: value)
      end
    end
  end

  # visible_fields should be an array of symbols or pairs of form [symbol, {inst: X}] where X is
  # the instance descriptor we should be looking in. If a plain symbol is passed, we assume instance 1.
  def expect_visible(visible_fields)
    # We transform visible_fields to the form {Questioning => [X, Y], ...} where X, Y are instance descriptors.
    visible_fields = {}.tap do |list|
      visible_fields.each do |item|
        if item.is_a?(Symbol)
          qing = questionings[item]
          inst = 1
        else
          qing = questionings[item[0]]
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
        page.all(%Q{div.qing-group-instance[data-group-id="#{qing.parent_id}"]}).size
      end

      # For each instance, check visibility.
      # TODO: When we add support for nested groups to this spec, we will have to respect the full
      # instance descriptor, not just a single number.
      (1..inst_count).each do |inst|
        currently_visible = (visible_fields[qing] || []).include?(inst)
        expect(page).to have_css(selector_for(qing, inst), visible: currently_visible)
      end
    end
  end

  # Gets a CSS selector for the answer_field div described by the given qing and instance descriptor.
  def selector_for(qing, inst)
    %Q{div.answer_field[data-qing-id="#{qing.id}"][data-inst-num="#{inst}"]}
  end
end
