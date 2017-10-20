require "spec_helper"

feature "conditions in responses", js: true do
  let(:user) { create(:user) }
  let!(:form) { create(:form) }
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
      text3: create_questioning("text", form)
    }
  end
  let!(:oset1) { qings[:select_one].option_set }
  let!(:oset2) { qings[:mlev_sel_one].option_set }
  let!(:oset3) { qings[:geo_sel_one].option_set }
  let!(:oset4) { qings[:select_multiple].option_set }

  let(:year) { Time.now.year - 2 }
  let(:form_qings) { form.questionings }

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
  end

  def create_cond(q:, ref_q:, op:, node: nil, value: nil)
    qings[q].display_conditions.create!(
      ref_qing: qings[ref_q],
      op: op,
      value: value,
      option_node: node
    )
  end

  def fill_and_expect_visible(q, value, visible)
    fill_answer(qing: qings[q], value: value)
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
    visible_qings = visible_qing_names.map { |qing_name| qings[qing_name] }
    visible_qing_ids = visible_qings.map(&:id)
    form_qings.each do |qing, i|
      currently_visible = visible_qing_ids.include?(qing.id)
      expect(page).to have_css("div.answer_field[data-qing-id=\"#{qing.id}\"]", visible: currently_visible)
    end
  end
end
