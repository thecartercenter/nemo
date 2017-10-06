require "spec_helper"

feature "conditions in responses", js: true do
  let(:user) { create(:user) }
  let!(:form) { create(:form) }
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
      text3: create_questioning("text", form)
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
        ref_qing: questionings[:time], op: "geq", value: "3:00pm")
    }
  end
  let(:year) { Time.now.year - 2 }
  let(:form_questionings) { form.questionings }


  scenario "should work" do
    login(user)
    visit(new_response_path(locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id))
    expect(page).to have_content("New Response")

    # fill in answers
    visible_qings = [:long_text, :text2]

    fill_answer_and_expect_visible(questioning: questionings[:long_text], value: "fo", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:long_text], value: "foo", visible: visible_qings << :text1)

    fill_answer_and_expect_visible(
      questioning: questionings[:text1], value: "bar", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:text1], value: "barz", visible: visible_qings << :integer)

    fill_answer_and_expect_visible(
      questioning: questionings[:integer], value: "10", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:integer], value: "11", visible: visible_qings << :counter)

    fill_answer_and_expect_visible(
      questioning: questionings[:counter], value: "5", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:counter], value: "6", visible: visible_qings << :decimal)

    fill_answer_and_expect_visible(
      questioning: questionings[:decimal], value: "21.7", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:decimal], value: "21.72", visible: visible_qings << :select_one)

    fill_answer_and_expect_visible(
      questioning: questionings[:select_one], value: "Cat", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:select_one], value: "Dog", visible: visible_qings << :multilevel_select_one)

    fill_answer_and_expect_visible(
      questioning: questionings[:multilevel_select_one], value: ["Plant"], visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:multilevel_select_one], value: ["Plant", "Oak"], visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:multilevel_select_one],
      value: ["Plant", "Tulip"],
      visible: visible_qings << :geo_multilevel_select_one)

    fill_answer_and_expect_visible(
      questioning: questionings[:geo_multilevel_select_one],
      value: ["Ghana"],
      visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:geo_multilevel_select_one],
      value: ["Canada"],
      visible: visible_qings << :select_multiple)

    fill_answer_and_expect_visible(
      questioning: questionings[:geo_multilevel_select_one],
      value: ["Canada", "Ottawa"],
      visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:select_multiple], value: ["Dog"], visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:select_multiple], value: ["Dog", "Cat"], visible: visible_qings << :datetime)

    fill_answer_and_expect_visible(
      questioning: questionings[:datetime], value: "#{year}-01-01 5:00:21", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:datetime], value: "#{year}-01-01 5:00:20", visible: visible_qings << :date)

    fill_answer_and_expect_visible(
      questioning: questionings[:date], value: "#{year}-03-21", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:date], value: "#{year}-03-22", visible: visible_qings << :time)

    fill_answer_and_expect_visible(
      questioning: questionings[:time], value: "6:00:00", visible: visible_qings)

    fill_answer_and_expect_visible(
      questioning: questionings[:time], value: "15:00:00", visible: visible_qings << :text3)
  end

  def fill_answer_and_expect_visible(questioning: nil, value: nil, visible: nil)
    fill_answer(qing: questioning, value: value)
    expect_visible(visible)
  end

  def fill_answer(qing: nil, value: nil)
    idx = "#{qing.id}_1"
    id = "response_answers_attributes_#{idx}_value"
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

  def expect_visible(visible_qing_names)
    visible_qings = visible_qing_names.map { |qing_name| questionings[qing_name] }
    visible_qing_ids = visible_qings.map(&:id)
    form_questionings.each do |qing, i|
      currently_visible = visible_qing_ids.include?(qing.id)
      expect(page).to have_css("div.answer_field[data-qing-id=\"#{qing.id}\"]", visible: currently_visible)
    end
  end
end
