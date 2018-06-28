require 'rails_helper'

feature 'report generation', js: true do
  before do
    @user = create(:user)

    @form = create(:form, question_types: %w(integer select_one text))
    @qs = @form.questions
    create(:response, form: @form, answer_values: %w(1 Cat Foo))
    create(:response, form: @form, answer_values: %w(2 Dog Bar))
    create(:response, form: @form, answer_values: %w(3 Dog Blah))

    login(@user)
  end

  # NONE OF THESE REPORTS ARE WORKING PROPERLY
  # They work only intermittently and randomly.
  # They seem to work fine with selenium but we're trying to go all-poltergeist.
  # For the list report test, it seems the 'change' event for the report type radio buttons
  # is failing to fire sometimes, even though the choose command succeds (I also tried using find(...).click)
  # Giving up for now.

  describe 'list report' do
    # scenario 'should work' do
    #   # Generate list report with two cols.
    #   visit(new_report_path(mode: 'm', mission_name: get_mission.compact_name, locale: 'en'))
    #   choose("List Report")
    #   3.times{ click_button("Next") }
    #   find(".buttons button.next").click
    #   find(".buttons button.next").click
    #   find(".buttons button.next").click
    #   click_link('Add Column')
    #   all('select.field')[0].select('Submitter Name')
    #   click_link('Add Column')
    #   all('select.field')[1].select(@qs[0].code)
    #   run_report_and_wait
    #   expect_cols(2)
    #
    #   # Remove last col and add new one.
    #   edit_report
    #   2.times{ click_button('Next') }
    #   expect(page).to have_selector('.report_form .fa-trash-o')
    #   all('.report_form a.remove').last.click
    #   click_link('Add Column')
    #   all('select.field')[1].select(@qs[1].code)
    #   run_report_and_wait
    #   expect_cols(2)
    # end
  end

  describe 'standard form report' do
    # before do
    #   @tag1 = build(:tag)
    #   @tag2 = build(:tag)
    #   @tag3 = build(:tag)
    #   @qs[0].tags = [@tag1]
    #   @qs[1].tags = [@tag2]
    #   @qs[2].tags = [@tag3, @tag1]
    # end
    #
    # scenario 'should work' do
    #   # Generate standard form report
    #   visit new_report_path(mode: 'm', mission_name: get_mission.compact_name, locale: 'en')
    #   choose 'Standard Form Report'
    #   click_button 'Next'
    #   select @form.name, from: 'form_id'
    #   fill_in 'report_title', with: 'SFR Test'
    #
    #   # Group questions by tag
    #   check 'group_by_tag'
    #   run_report_and_wait
    #   expect(page).to have_selector '.tag-header', count: 4
    #   expect(page).to have_selector '.tag-header', text: /questions tagged #{@tag1.name}/i
    #   expect(page).to have_selector '.tag-header', text: /untagged questions/i
    #
    #   # Check that group by tag is checked
    #   visit reports_path(mode: 'm', mission_name: get_mission.compact_name, locale: 'en')
    #   click_link 'SFR Test'
    #   edit_report
    #   expect(find('#group_by_tag')).to be_checked
    # end
  end

  def run_report_and_wait
    click_button('Run')
    expect(page).to have_selector('.report_body tr td')
  end

  def edit_report
    click_link('Edit Report')
    expect(page).to have_selector('.modal-title', text: /Edit Report/)
  end

  def expect_cols(num)
    expect(all('.report_body tr:first-child th').size).to eq num
  end
end
