require 'spec_helper'

feature 'conditions flow', js: true do
  before do
    @user = create(:user)
    @form = create(:form, name: 'Foo', question_types: %w(select_one text), use_multilevel_option_set: true)
    login(@user)
  end

  scenario 'should work' do
    click_link('Forms')

    # Add a condition to question 2 referencing question 1.
    find('a.action_link_edit').click
    expect(page).to have_content('Edit Form') # Wait for index.
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
    page.evaluate_script('window.history.back()')
    expect(page).to have_content('Edit Form') # Wait for index.
    all('a.action_link_edit')[1].click
    select('Dog', from: 'Species')
    click_button('Save')

    # View and test again.
    click_link(@form.questions[1].name)
    expect(page).to have_content("Question #1 #{@form.questions[0].code}
      Species is equal to \"Dog\"")

    # Add question with condition to form
    page.evaluate_script('window.history.back()')
    expect(page).to have_content('Edit Form') # Wait for index.
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
end
