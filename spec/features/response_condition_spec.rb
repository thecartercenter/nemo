require "spec_helper"

feature "conditions in responses", js: true do
  let(:user) { create(:user) }
  let!(:form) { create(:form) }
  let(:group) { create(:qing_group, form: form) }
  let(:rpt_group) { create(:qing_group, form: form, repeatable: true) }
  let!(:qings) do
    {
      long_text: create_questioning("long_text", form),
      text1: create_questioning("text", form),
      integer: create_questioning("integer", form),
      counter: create_questioning("counter", form),
      text2: create_questioning("text", form),
      decimal: create_questioning("decimal", form),
      select_one: create_questioning("select_one", form),
      mlev_sel_one: create_questioning("multilevel_select_one", form),
      geo_sel_one: create_questioning("geo_multilevel_select_one", form),
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
  let(:oset1) { qings[:select_one].option_set }
  let(:oset2) { qings[:mlev_sel_one].option_set }
  let(:oset3) { qings[:geo_sel_one].option_set }
  let(:oset4) { qings[:select_multiple].option_set }
  let(:year) { Time.now.year - 2 }

  before do
    create_cond(q: :text1, ref_q: :long_text, op: "eq", value: "foo")
    create_cond(q: :integer, ref_q: :text1, op: "neq", value: "bar")
    create_cond(q: :counter, ref_q: :integer, op: "gt", value: "10")
    create_cond(q: :decimal, ref_q: :counter, op: "gt", value: "5")
    create_cond(q: :select_one, ref_q: :decimal, op: "eq", value: "21.72")
    create_cond(q: :mlev_sel_one, ref_q: :select_one, op: "eq", node: oset1.node("Dog"))
    create_cond(q: :geo_sel_one, ref_q: :mlev_sel_one, op: "eq", node: oset2.node("Plant", "Tulip"))
    create_cond(q: :select_multiple, ref_q: :geo_sel_one, op: "eq", node: oset3.node("Canada"))
    create_cond(q: :datetime, ref_q: :select_multiple, op: "inc", node: oset4.node("Cat"))
    create_cond(q: :date, ref_q: :datetime, op: "lt", value: "#{year}-01-01 5:00:21")
    create_cond(q: :time, ref_q: :date, op: "eq", value: "#{year}-03-22")
    create_cond(q: :text3, ref_q: :time, op: "geq", value: "3:00pm")
    create_cond(q: :rpt1, ref_q: :text3, op: "eq", value: "baz") # References top level Q
    create_cond(q: :rpt2, ref_q: :rpt1, op: "eq", value: "qux") # References same group Q
    create_cond(q: :rpt3, ref_q: :grp1, op: "eq", value: "nix") # References Q from sibling group
  end

  scenario "should work" do
    login(user)
    visit(new_response_path(locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id))
    expect(page).to have_content("New Response")

    visible = [:long_text, :text2]
    fill_and_expect_visible(:long_text, "fo", visible)
    fill_and_expect_visible(:long_text, "foo", visible << :text1)
    fill_and_expect_visible(:text1, "bar", visible)
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

  def create_cond(q:, ref_q:, op:, node: nil, value: nil)
    qings[q].display_conditions.create!(
      ref_qing: qings[ref_q],
      op: op,
      value: value,
      option_node: node
    )
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
