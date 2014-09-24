require 'spec_helper'

Selenium::WebDriver::Driver.class_eval do
  def quit
    #STDOUT.puts "#{self.class}#quit: no-op"
  end
end

feature 'conditions in responses', js: true do
  before do
    @user = create(:user)
    @form = create(:form, name: 'Foo',
      question_types: %w(long_text text integer text decimal select_one select_multiple datetime date time text))

    # Create conditions referring to each question except #4 and the last one.
    @qings = @form.questionings
    @qings[1].create_condition(ref_qing: @qings[0], op: 'eq', value: 'foo')
    @qings[2].create_condition(ref_qing: @qings[1], op: 'neq', value: 'bar')
    @qings[4].create_condition(ref_qing: @qings[2], op: 'gt', value: '10')
    @qings[5].create_condition(ref_qing: @qings[4], op: 'eq', value: '21.72')
    @qings[6].create_condition(ref_qing: @qings[5], op: 'eq', option_ids: [@qings[5].options.last.id])
    @qings[7].create_condition(ref_qing: @qings[6], op: 'inc', option_ids: [@qings[5].options.first.id])
    @qings[8].create_condition(ref_qing: @qings[7], op: 'lt', value: '2001-01-01 5:00')
    @qings[9].create_condition(ref_qing: @qings[8], op: 'eq', value: '2005-03-22')
    @qings[10].create_condition(ref_qing: @qings[9], op: 'geq', value: '3:00pm')

    login(@user)
    visit(new_response_path(locale: 'en', mode: 'm', mission_name: get_mission.compact_name, form_id: @form.id))
    expect(page).to have_content('New Response')
  end

  scenario 'should work' do
    fill_answer(0, type: 'long_text', with: 'fo')
    expect_visible(0,3)
    fill_answer(0, type: 'long_text', with: 'foo')
    expect_visible(0,1,3)
  end

  def fill_answer(idx, params)
    id = "response_answer_sets_#{idx}_value"
    case params[:type]
    when 'long_text'
      fill_in_ckeditor(id, params.slice(:with))
    else
      fill_in(id, with: params[:with])
    end
  end

  def expect_visible(*visible)
    @qings.each_with_index{ |q,i| expect(page).to have_selector("div.answer_field[data-index=\"#{i}\"]", visible: visible.include?(i)) }
  end

  def fill_in_ckeditor(locator, opts)
    #sleep 1000
    #expect(page).to have_selector("#cke_#{locator} iframe") # Wait for ckeditor to load
    content = opts.fetch(:with).to_json
    page.execute_script <<-SCRIPT
      CKEDITOR.instances['#{locator}'].setData(#{content});
      $('textarea##{locator}').text(#{content});
    SCRIPT
  end
end
