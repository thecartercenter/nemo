require 'spec_helper'

feature 'conditions flow', js: true do
  before do
    @user = create(:user)
    @form = create(:form, name: 'Foo', question_types: %w(select_one integer text), use_multilevel_option_set: true)
    login(@user)
    visit(edit_form_path(@form, locale: 'en', mode: 'm', mission_name: get_mission.compact_name))
    expect(page).to have_content('Edit Form')
  end

  scenario 'add and update condition to existing question' do
    all('a.action_link_edit')[1].click
    select("1. #{@form.questions[0].code}", from: 'Question')
    select('is equal to', from: 'Comparison')
    select('Animal', from: 'Kingdom')
    click_button('Save')

    # View the questioning and ensure the condition is shown correctly.
    click_link(@form.questions[1].name)
    expect(page).to have_content("Question #1 #{@form.questions[0].code}
      Kingdom is equal to \"Animal\"")

    # Update the condition to have a full option path.
    visit("/en/m/#{@form.mission.compact_name}/forms/#{@form.id}/edit")
    all('a.action_link_edit')[1].click
    select('Dog', from: 'Species')
    click_button('Save')

    # View and test again.
    click_link(@form.questions[1].name)
    expect(page).to have_content("Question #1 #{@form.questions[0].code}
      Species is equal to \"Dog\"")
  end

  scenario 'add a new question with a condition' do
    click_link('Add Questions')
    fill_in('Code', with: 'NewQ')
    select('Text', from: 'Type')
    fill_in('Title (English)', with: 'New Question')
    select("1. #{@form.questions[0].code}", from: 'Question')
    select('is equal to', from: 'Comparison')
    select('Plant', from: 'Kingdom')
    select('Oak', from: 'Species')
    click_button('Save')

    # Check the new condition
    click_link('New Question')
    expect(page).to have_content("Question #1 #{@form.questions[0].code}
      Species is equal to \"Oak\"")
  end

  scenario 'add a condition referring to an integer question' do
    all('a.action_link_edit')[2].click
    select("2. #{@form.questions[1].code}", from: 'Question')
    select('is less than', from: 'Comparison')
    fill_in('Value', with: '5')
    click_button('Save')

    # View the questioning and ensure the condition is shown correctly.
    click_link(@form.questions[2].name)
    expect(page).to have_content("Question #2 #{@form.questions[1].code} is less than 5")
  end
end
