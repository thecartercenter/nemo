require 'spec_helper'

feature 'responses form' do
  before do
    @user = create(:user)
  end

  describe 'general' do # This should be refactored to split into different scenarios.
    before do
      @form = create(:sample_form)
      @form.publish!
      login(@user)
    end

    scenario 'should work', js: true do
      click_link('Submit')
      click_link(@form.name)
      expect(page).to have_selector('h1', text: 'New Response')
      select(@user.name, from: 'response_user_id')

      # Fill in answers
      select('Dog', from: 'response_answer_sets_0_answers_0_option_id')
      select('Plant', from: 'response_answer_sets_1_answers_0_option_id')
      select('Oak', from: 'response_answer_sets_1_answers_1_option_id')

      # Save and check it worked.
      click_button('Save')
      expect(page).to have_selector('h1', text: 'Response')

      # Check show mode.
      click_link(Response.first.id.to_s)
      %w(Dog Plant Oak).each{ |o| expect(page).to have_selector('div.option-name', text: o) }

      # Check edit mode.
      click_link('Edit Response')
      select('Animal', from: 'response_answer_sets_1_answers_0_option_id')
      select('Cat', from: 'response_answer_sets_1_answers_1_option_id')
      click_button('Save')

      # Check that change occurred.
      click_link(Response.first.id.to_s)
      %w(Dog Animal Cat).each{ |o| expect(page).to have_selector('div.option-name', text: o) }

      # Delete.
      click_link('Delete Response')
      page.driver.browser.switch_to.alert.accept
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
      visit(new_response_path(locale: 'en', mode: 'm', mission_name: get_mission.compact_name, form_id: @form.id))
      expect(page).not_to have_selector("div.form_field#qing_#{@qing1.id}")
      select(@user.name, from: 'response_user_id')
      fill_in('response_answer_sets_0_value', with: 'Foo')
      click_button('Save')

      # Ensure response saved properly.
      click_link(Response.first.id.to_s)
      expect(page).not_to have_selector("div.form_field#qing_#{@qing1.id}")
      expect(page).to have_selector("div.form_field#qing_#{@qing0.id} .control", text: 'Foo')
    end
  end
end
