require 'spec_helper'

feature 'conditions in responses', js: true, driver: :selenium do
  before do
    @user = create(:user)
    @form = create(:form, name: 'Foo',
      question_types: %w(long_text text integer text decimal select_one multi_level_select_one multi_level_select_one select_multiple datetime date time text))
    @year = Time.now.year - 2
    @qings = @form.questionings
    @os2 = @qings[6].option_set
    @os3 = @qings[7].option_set

    # Create conditions referring to each question except #4 and the last one.
    @qings[1].create_condition(ref_qing: @qings[0], op: 'eq', value: 'foo')
    @qings[2].create_condition(ref_qing: @qings[1], op: 'neq', value: 'bar')
    @qings[4].create_condition(ref_qing: @qings[2], op: 'gt', value: '10')
    @qings[5].create_condition(ref_qing: @qings[4], op: 'eq', value: '21.72')
    @qings[6].create_condition(ref_qing: @qings[5], op: 'eq', option_ids: [@qings[5].options.last.id]) # Dog
    @qings[7].create_condition(ref_qing: @qings[6], op: 'eq',
      option_ids: [@os2.c[1].option_id, @os2.c[1].c[0].option_id]) # Plant > Tulip
    @qings[8].create_condition(ref_qing: @qings[7], op: 'eq',
      option_ids: [@os3.c[0].option_id]) # Animal (this tests partial multilevel response)
    @qings[9].create_condition(ref_qing: @qings[8], op: 'inc', option_ids: [@qings[8].options.first.id]) # Cat
    @qings[10].create_condition(ref_qing: @qings[9], op: 'lt', value: "#{@year}-01-01 5:00")
    @qings[11].create_condition(ref_qing: @qings[10], op: 'eq', value: "#{@year}-03-22")
    @qings[12].create_condition(ref_qing: @qings[11], op: 'geq', value: '3:00pm')

    login(@user)
    visit(new_response_path(locale: 'en', mode: 'm', mission_name: get_mission.compact_name, form_id: @form.id))
    expect(page).to have_content('New Response')
  end

  scenario 'should work' do
    fill_answer_and_expect_visible(0, 'fo', [0,3])
    fill_answer_and_expect_visible(0, 'foo', 0..3)
    fill_answer_and_expect_visible(1, 'bar', [0,1,3])
    fill_answer_and_expect_visible(1, 'barz', 0..3)
    fill_answer_and_expect_visible(2, '10', 0..3)
    fill_answer_and_expect_visible(2, '11', 0..4)
    fill_answer_and_expect_visible(4, '21.7', 0..4)
    fill_answer_and_expect_visible(4, '21.72', 0..5)
    fill_answer_and_expect_visible(5, 'Cat', 0..5)
    fill_answer_and_expect_visible(5, 'Dog', 0..6)
    fill_answer_and_expect_visible(6, ['Plant'], 0..6)
    fill_answer_and_expect_visible(6, ['Plant', 'Oak'], 0..6)
    fill_answer_and_expect_visible(6, ['Plant', 'Tulip'], 0..7)
    fill_answer_and_expect_visible(7, ['Plant'], 0..7)
    fill_answer_and_expect_visible(7, ['Animal'], 0..8)
    fill_answer_and_expect_visible(7, ['Animal', 'Dog'], 0..8)
    fill_answer_and_expect_visible(8, ['Dog'], 0..8)
    fill_answer_and_expect_visible(8, ['Dog', 'Cat'], 0..9)
    fill_answer_and_expect_visible(9, "#{@year}-01-01 5:00", 0..9)
    fill_answer_and_expect_visible(9, "#{@year}-01-01 4:59", 0..10)
    fill_answer_and_expect_visible(10, "#{@year}-03-21", 0..10)
    fill_answer_and_expect_visible(10, "#{@year}-03-22", 0..11)
    fill_answer_and_expect_visible(11, "6:00", 0..11)
    fill_answer_and_expect_visible(11, "15:00", 0..12)
  end

  def fill_answer_and_expect_visible(idx, value, expect)
    fill_answer(idx, value)
    expect_visible(expect)
  end

  def fill_answer(idx, value)
    id = "response_answers_attributes_#{idx}_value"
    qtype_name = @qings[idx].qtype_name
    case qtype_name
    when 'long_text'
      fill_in_ckeditor(id, with: value)
    when 'select_one'
      if value.is_a?(Array)
        value.each_with_index do |o,i|
          id = "response_answers_attributes_#{idx}_#{i}_option_id"
          find("#response_answers_attributes_#{idx}_#{i}_option_id option", text: o)
          select(o, from: id)
        end
      else
        select(value, from: "response_answers_attributes_#{idx}_option_id")
      end
    when 'select_multiple'
      @qings[idx].options.each_with_index do |o,i|
        id = "response_answers_attributes_#{idx}_choices_attributes_#{i}_checked"
        value.include?(o.name) ? check(id) : uncheck(id)
      end
    when 'datetime', 'date', 'time'
      t = Time.parse(value)
      prefix = "response_answers_attributes_#{idx}_#{qtype_name}_value"
      unless qtype_name == 'time'
        select(t.strftime('%Y'), from: "#{prefix}_1i")
        select(t.strftime('%B'), from: "#{prefix}_2i")
        select(t.day.to_s, from: "#{prefix}_3i")
      end
      unless qtype_name == 'date'
        select(t.strftime('%H'), from: "#{prefix}_4i")
        select(t.strftime('%M'), from: "#{prefix}_5i")
      end
    else
      fill_in(id, with: value)
    end
  end

  def expect_visible(visible)
    visible = visible.to_a if visible.is_a?(Range)
    @qings.each_with_index do |q,i|
      cur_vis = visible.include?(i)

      # We do it this way (find, then assert) for timing issues.
      expect(find("div.answer_field[data-index=\"#{i}\"]", visible: cur_vis)).send(cur_vis ? :to : :not_to, be_visible)
    end
  end
end
