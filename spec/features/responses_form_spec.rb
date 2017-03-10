require 'spec_helper'

# Should change this to no_sphinx for performance reasons when TS bug #914 is fixed.
feature 'responses form', js: true, sphinx: true do
  before do
    @user = create(:user)
  end

  describe 'general' do # This should be refactored to split into different scenarios.
    before do
      @form = create(:form, question_types: %w(select_one multilevel_select_one select_multiple integer decimal
        location text long_text datetime date time))
      @qings = @form.questionings
      @form.publish!
      login(@user)
    end

    let!(:reviewer) { create(:user) }

    scenario 'should work' do
      visit_submit_page_and_select_user

      # Fill in answers
      select('Dog', from: control_id(@qings[0], '_option_node_id'))

      select('Plant', from: control_id(@qings[1], '_0_option_node_id'))
      find('#' + control_id(@qings[1], '_1_option_node_id') + ' option', text: 'Oak')
      select('Oak', from: control_id(@qings[1], '_1_option_node_id'))

      check(control_id(@qings[2], '_choices_attributes_0_checked')) # Cat
      fill_in(control_id(@qings[3], '_value'), with: '10')
      fill_in(control_id(@qings[4], '_value'), with: '10.2')
      fill_in(control_id(@qings[5], '_value'), with: '42.277976 -83.817573')
      fill_in(control_id(@qings[6], '_value'), with: 'Foo')
      fill_in_ckeditor(control_id(@qings[7], '_value'), with: "Foo Bar\nBaz")

      select(Time.now.year, from: control_id(@qings[8], '_datetime_value_1i'))
      select('March', from: control_id(@qings[8], '_datetime_value_2i'))
      select('12', from: control_id(@qings[8], '_datetime_value_3i'))
      select('18', from: control_id(@qings[8], '_datetime_value_4i'))
      select('32', from: control_id(@qings[8], '_datetime_value_5i'))

      select(Time.now.year, from: control_id(@qings[9], '_date_value_1i'))
      select('October', from: control_id(@qings[9], '_date_value_2i'))
      select('26', from: control_id(@qings[9], '_date_value_3i'))

      select('03', from: control_id(@qings[10], '_time_value_4i'))
      select('08', from: control_id(@qings[10], '_time_value_5i'))

      # Save and check it worked.
      click_button('Save')
      expect(page).to have_selector('h1', text: 'Response')

      # Check show mode.
      click_link(Response.first.id.to_s)
      check_response_show_form('Dog', %w(Plant Oak), 'Cat', '10', '10.2', '42.277976 -83.817573', 'Foo',
        "Foo Bar Baz", "Mar 12 #{Time.now.year} 18:32", "Oct 26 #{Time.now.year}", "03:08")

      # Check edit mode.
      click_link('Edit Response')
      select2(reviewer.name, from: "response_reviewer_id")
      select('Animal', from: control_id(@qings[1], '_0_option_node_id'))
      find('#' + control_id(@qings[1], '_1_option_node_id') + ' option', text: 'Cat')
      select('Cat', from: control_id(@qings[1], '_1_option_node_id'))
      uncheck(control_id(@qings[2], '_choices_attributes_0_checked')) # Cat
      check(control_id(@qings[2], '_choices_attributes_1_checked')) # Dog
      click_button('Save')

      # Check that change occurred.
      click_link(Response.first.id.to_s)
      check_response_show_form('Dog', %w(Animal Cat), 'Dog', '10', '10.2', '42.277976 -83.817573', 'Foo',
        "Foo Bar Baz", "Mar 12 #{Time.now.year} 18:32", "Oct 26 #{Time.now.year}", "03:08")

      # Delete.
      handle_js_confirm{click_link('Delete Response')}
      expect(page).to have_selector('.alert-success', text: 'deleted')
    end
  end

  describe 'hidden questions' do
    before do
      @form = create(:form, question_types: %w(text text))
      @qing0, @qing1 = @form.questionings
      @qing1.update_attributes(hidden: true, required: true) # Being required shouldn't make a difference.
      @form.publish!
      login(@user)
    end

    scenario 'should be properly ignored' do
      visit_submit_page_and_select_user

      expect(page).not_to have_selector("div.form_field#qing_#{@qing1.id}")
      fill_in(control_id(@qing0, '_value'), with: 'Foo')
      click_button('Save')

      # Ensure response saved properly.
      click_link(Response.first.id.to_s)
      expect(page).not_to have_selector("[data-qing-id=\"#{@qing1.id}\"]")
      expect(page).to have_selector("[data-qing-id=\"#{@qing0.id}\"] .ro-val", text: 'Foo')
    end
  end

  describe 'integer constraints' do
    before do
      @form = create(:form, question_types: %w(integer))
      @form.questions[0].update_attributes!(minimum: 10)
      @qings = @form.questionings
      login(@user)
    end

    scenario 'should be enforced if appropriate' do
      # Should raise error if value filled in.
      visit_submit_page_and_select_user
      fill_in(control_id(@qings[0], '_value'), with: '9')
      click_button('Save')
      expect(page).to have_content('greater than or equal to 10')

      # Should not raise error if value is valid.
      fill_in(control_id(@qings[0], '_value'), with: '11')
      click_button('Save')
      expect(page).to have_content('Response created successfully')

      # Should not raise error if left blank.
      visit_submit_page_and_select_user
      fill_in(control_id(@qings[0], '_value'), with: '')
      click_button('Save')
      expect(page).to have_content('Response created successfully')
    end
  end

  describe 'reviewer notes' do

    before do
      @observer = create(:user, role_name: :observer)
      @form = create(:form, question_types: %w(integer))
      @response = create(:response, :is_reviewed, form: @form, answer_values: [0], user: @observer)
    end

    let(:notes) { @response.reviewer_notes }

    scenario 'should not be visible to normal users' do
      login(@observer)
      visit(response_path(@response, locale: 'en', mode: 'm', mission_name: get_mission.compact_name))
      expect(page).not_to have_content(notes)
    end

    scenario 'should be visible to admin' do
      login(create(:user, admin: true))
      visit(response_path(@response, locale: 'en', mode: 'm', mission_name: get_mission.compact_name))
      expect(page).to have_content(notes)
    end

    scenario 'should be visible to staffer' do
      login(create(:user, role_name: :staffer))
      visit(response_path(@response, locale: 'en', mode: 'm', mission_name: get_mission.compact_name))
      expect(page).to have_content(notes)
    end
  end

  describe 'repeat groups' do
    before do
      @form = create(:form, question_types: ['select_one', ['integer', 'text', 'multilevel_select_one'], 'text'])
      @group = @form.child_groups.first
      @group.update_attribute(:repeatable, true)
      @qings = @form.questionings
      @form.publish!
      login(@user)
    end

    scenario 'should let you add two instances' do
      visit_submit_page_and_select_user

      select 'Cat', from: control_id(@qings[0], '_option_node_id')
      find("a.add-instance").click
      fill_in control_id(@qings[1], '_value', inst_num: 2), with: 10
    end
  end

  def control_id(qing, suffix, inst_num: 1)
    "response_answers_attributes_#{qing.id}_#{inst_num}#{suffix}"
  end

  def visit_submit_page_and_select_user
    visit(new_response_path(locale: 'en', mode: 'm', mission_name: get_mission.compact_name, form_id: @form.id))
    select2(@user.name, from: 'response_user_id')
  end

  def check_response_show_form(*values)
    values.each_with_index{ |v,i| expect_answer(i, v) }
  end

  def expect_answer(qing_idx, value)
    qing = @qings[qing_idx]
    csscls = qing.multilevel? ? 'option-name' : 'ro-val'
    Array.wrap(value).each do |v|
      expect(page).to have_selector("[data-qing-id=\"#{qing.id}\"] .#{csscls}", text: /^#{Regexp.escape(v)}$/)
    end
  end

  # helper method
  def handle_js_confirm
    page.evaluate_script 'window.confirmMsg = null'
    page.evaluate_script 'window.confirm = function(msg) { window.confirmMsg = msg; return true; }'
    yield
    page.evaluate_script 'window.confirmMsg'
  end
end
