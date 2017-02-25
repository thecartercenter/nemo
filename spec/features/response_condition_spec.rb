require 'spec_helper'

feature 'conditions in responses', js: true do
  before do
    @user = create(:user)
    @form = create(:form, name: 'Foo',
      question_types: [
        "long_text",             #  0
        "text",                  #  1
        "integer",               #  2
        "text",                  #  3
        "decimal",               #  4
        "select_one",            #  5
        "multilevel_select_one", #  6
        "multilevel_select_one", #  7
        "select_multiple",       #  8
        "datetime",              #  9
        "date",                  # 10
        "time",                  # 11
        "text"                   # 12
    ])
    @year = Time.now.year - 2
    @qings = @form.questionings
    @os2 = @qings[6].option_set
    @os3 = @qings[7].option_set

    # Create conditions referring to each question except #4 and the last one.
    @qings[1].create_condition(ref_qing: @qings[0], op: 'eq', value: 'foo')
    @qings[2].create_condition(ref_qing: @qings[1], op: 'neq', value: 'bar')
    @qings[4].create_condition(ref_qing: @qings[2], op: 'gt', value: '10')
    @qings[5].create_condition(ref_qing: @qings[4], op: 'eq', value: '21.72')
    @qings[6].create_condition(ref_qing: @qings[5], op: 'eq', option_node: @qings[5].option_set.c[1]) # Dog
    @qings[7].create_condition(ref_qing: @qings[6], op: 'eq', option_node: @os2.c[1].c[0]) # Plant > Tulip
    @qings[8].create_condition(ref_qing: @qings[7], op: 'eq', option_node: @os3.c[0]) # Animal (partial resp.)
    @qings[9].create_condition(ref_qing: @qings[8], op: 'inc', option_node: @qings[8].option_set.c[0]) # Cat
    @qings[10].create_condition(ref_qing: @qings[9], op: 'lt', value: "#{@year}-01-01 5:00")
    @qings[11].create_condition(ref_qing: @qings[10], op: 'eq', value: "#{@year}-03-22")
    @qings[12].create_condition(ref_qing: @qings[11], op: 'geq', value: '3:00pm')

    login(@user)
    visit(new_response_path(locale: 'en', mode: 'm', mission_name: get_mission.compact_name, form_id: @form.id))
    expect(page).to have_content('New Response')
  end

  scenario 'should work' do
    fill_answer_and_expect_visible(@qings[0], 'fo', [0,3])
    fill_answer_and_expect_visible(@qings[0], 'foo', 0..3)
    fill_answer_and_expect_visible(@qings[1], 'bar', [0,1,3])
    fill_answer_and_expect_visible(@qings[1], 'barz', 0..3)
    fill_answer_and_expect_visible(@qings[2], '10', 0..3)
    fill_answer_and_expect_visible(@qings[2], '11', 0..4)
    fill_answer_and_expect_visible(@qings[4], '21.7', 0..4)
    fill_answer_and_expect_visible(@qings[4], '21.72', 0..5)
    fill_answer_and_expect_visible(@qings[5], 'Cat', 0..5)
    fill_answer_and_expect_visible(@qings[5], 'Dog', 0..6)
    fill_answer_and_expect_visible(@qings[6], ['Plant'], 0..6)
    fill_answer_and_expect_visible(@qings[6], ['Plant', 'Oak'], 0..6)
    fill_answer_and_expect_visible(@qings[6], ['Plant', 'Tulip'], 0..7)
    fill_answer_and_expect_visible(@qings[7], ['Plant'], 0..7)
    fill_answer_and_expect_visible(@qings[7], ['Animal'], 0..8)
    fill_answer_and_expect_visible(@qings[7], ['Animal', 'Dog'], 0..8)
    fill_answer_and_expect_visible(@qings[8], ['Dog'], 0..8)
    fill_answer_and_expect_visible(@qings[8], ['Dog', 'Cat'], 0..9)
    fill_answer_and_expect_visible(@qings[9], "#{@year}-01-01 5:00", 0..9)
    fill_answer_and_expect_visible(@qings[9], "#{@year}-01-01 4:59", 0..10)
    fill_answer_and_expect_visible(@qings[10], "#{@year}-03-21", 0..10)
    fill_answer_and_expect_visible(@qings[10], "#{@year}-03-22", 0..11)
    fill_answer_and_expect_visible(@qings[11], "6:00", 0..11)
    fill_answer_and_expect_visible(@qings[11], "15:00", 0..12)
  end

  def fill_answer_and_expect_visible(qing, value, expect)
    fill_answer(qing, value)
    expect_visible(expect)
  end

  def fill_answer(qing, value)
    idx = "#{qing.id}_1"
    id = "response_answers_attributes_#{idx}_value"
    case qing.qtype_name
    when 'long_text'
      fill_in_ckeditor(id, with: value)
    when 'select_one'
      if value.is_a?(Array)
        value.each_with_index do |o,i|
          id = "response_answers_attributes_#{idx}_#{i}_option_node_id"
          find("#response_answers_attributes_#{idx}_#{i}_option_node_id option", text: o)
          select(o, from: id)
        end
      else
        select(value, from: "response_answers_attributes_#{idx}_option_node_id")
      end
    when 'select_multiple'
      qing.options.each_with_index do |o,i|
        id = "response_answers_attributes_#{idx}_choices_attributes_#{i}_checked"
        value.include?(o.name) ? check(id) : uncheck(id)
      end
    when 'datetime', 'date', 'time'
      t = Time.parse(value)
      prefix = "response_answers_attributes_#{idx}_#{qing.qtype_name}_value"
      unless qing.qtype_name == 'time'
        select(t.strftime('%Y'), from: "#{prefix}_1i")
        select(t.strftime('%B'), from: "#{prefix}_2i")
        select(t.day.to_s, from: "#{prefix}_3i")
      end
      unless qing.qtype_name == 'date'
        select(t.strftime('%H'), from: "#{prefix}_4i")
        select(t.strftime('%M'), from: "#{prefix}_5i")
      end
    else
      fill_in(id, with: value)
    end
  end

  def expect_visible(visible)
    visible = visible.to_a if visible.is_a?(Range)
    @qings.each_with_index do |qing,i|
      cur_vis = visible.include?(i)
      expect(page).to have_css("div.answer_field[data-qing-id=\"#{qing.id}\"]", visible: cur_vis)
    end
  end
end
