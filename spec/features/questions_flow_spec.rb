require "spec_helper"

feature "questions flow" do
  before do
    @mission = get_mission

    @question1 = create(:question, name: "How many cheeses?")
    @question2 = create(:question, name: "How many wines?")
    @question3 = create(:question, name: "How much beer?", is_standard: true, mission_id: nil)

    @form = create(:form)
    @questioning1 = create(:questioning, form: @form, question: @question1)
    @questioning2 = create(:questioning, form: @form, question: @question2)
    @questioning3 = create(:questioning, form: create(:form, is_standard: true, mission_id: nil), question: @question3)

    @tag1 = create(:tag, name: "thriftshop", mission_id: @mission.id)
    @tag2 = create(:tag, name: "twenty dollaz", mission_id: @mission.id)
    @tag3 = create(:tag, name: "awesome", mission_id: nil)

    @user = create(:user, role_name: 'coordinator', admin: true)
    login(@user)
  end

  scenario 'search' do
    visit "/en/m/#{@mission.compact_name}/questions"
    expect(page).to have_content("Displaying all 2 Questions")
    expect(page).to have_content(@question1.code)
    expect(page).to have_content(@question2.code)

    # Working search.
    search_for('cheese')
    expect(page).to have_content(@question1.code)
    expect(page).not_to have_content(@question2.code)

    # Failing search.
    search_for('bobby fisher')
    expect(page).to have_content("No Questions found")

    # Empty search.
    search_for('')
    expect(page).to have_content("Displaying all 2 Questions")

    # Search error.
    search_for('creepy:')
    expect(page).to have_content("Error: Your search query could not be understood due to unexpected text near the end.")
  end

  def search_for(query)
    fill_in("search", with: query)
    click_button("Search")
  end

  scenario 'question tag add/remove', js: true, driver: :selenium do
    tag_add_remove_test(
      qtype: 'question',
      edit_path: edit_question_path(@question1, mode: 'm', mission_name: @mission.compact_name, locale: 'en'),
      show_path: question_path(@question1, mode: 'm', mission_name: @mission.compact_name, locale: 'en'),
      admin_edit_path: edit_question_path(@question3, mode: 'admin', mission_name: nil, locale: 'en'),
      admin_show_path: question_path(@question3, mode: 'admin', mission_name: nil, locale: 'en'),
      input_id: "token-input-question_tag_ids",
      table_row_id: %{tr[id="question_#{@question1.id}"]},
    )
  end

  scenario 'questioning tag add/remove', js: true, driver: :selenium do
    tag_add_remove_test(
      qtype: 'questioning',
      edit_path: edit_questioning_path(@questioning1, mode: 'm', mission_name: @mission.compact_name, locale: 'en'),
      show_path: questioning_path(@questioning1, mode: 'm', mission_name: @mission.compact_name, locale: 'en'),
      admin_edit_path: edit_questioning_path(@questioning3, mode: 'admin', mission_name: nil, locale: 'en'),
      admin_show_path: questioning_path(@questioning3, mode: 'admin', mission_name: nil, locale: 'en'),
      input_id: "token-input-questioning_question_attributes_tag_ids",
      table_row_id: %{tr[id="questioning_#{@questioning1.id}"]},
    )
  end

  def tag_add_remove_test(options = {})
    visit options[:edit_path]
    expect(page).to have_content "Tags:"

    # Mission tags
    fill_in options[:input_id], with: "t"
    expect(page).to have_content "thriftshop"
    expect(page).to have_content "twenty dollaz"

    fill_in options[:input_id], with: "th"
    expect(page).to have_content "thriftshop"
    expect(page).not_to have_content "twenty dollaz"
    expect(page).to have_content "th [New tag]"

    # Apply tag
    find('li', text: "thriftshop").click

    # Admin-mode tags should not appear here.
    fill_in options[:input_id], with: "a"
    expect(page).not_to have_content "awesome"

    # Create a new tag
    fill_in options[:input_id], with: "in my pocket"
    find('li', text: "in my pocket").click

    # Add and then cancel a new tag
    fill_in options[:input_id], with: "pop some tags"
    find('li', text: "pop some tags").click
    within find('div#tag_ids li', text: "pop some tags") do
      find('span.token-input-delete-token-elmo').click # "x" close button
    end
    expect(page).not_to have_content "pop some tags"

    click_button "Save"

    # New tag should be in database
    expect(Tag.find_by_name('in my pocket').mission_id).to eq @mission.id
    # Canceled tag should not
    expect(Tag.pluck(:name)).not_to include('pop some tags')

    # Tags show in question's row on index page
    expect(page).to have_content /Displaying (all \d+)? Questions/ # Check that index page has loaded
    within options[:table_row_id] do
      expect(page).to have_selector 'li', text: "thriftshop"
      expect(page).to have_selector 'li', text: "in my pocket"
    end

    # On questions index page, also check that tags show at top
    if options[:qtype] == 'question'
      within 'div.all-tags' do
        expect(page).to have_selector 'li', text: "thriftshop"
        expect(page).to have_selector 'li', text: "in my pocket"
      end
    end

    # Tags show on question(ing) show page
    visit options[:show_path]
    within "div#tag_ids" do
      expect(page).to have_selector 'li', text: "thriftshop"
      expect(page).to have_selector 'li', text: "in my pocket"
      expect(page).not_to have_selector 'li', text: "pop some tags"
    end

    # Admin mode
    visit options[:admin_edit_path]

    fill_in options[:input_id], with: "o"
    expect(page).to have_content "awesome"
    expect(page).not_to have_content "in my pocket" # Non-standard tag
    find('li', text: "awesome").click

    # Create a new tag
    fill_in options[:input_id], with: "come-up"
    find('li', text: /come-up/).click

    click_button "Save"

    # Tags show on question(ing) page
    visit options[:admin_show_path]
    within "div#tag_ids" do
      expect(page).to have_selector 'li', text: "awesome"
    end

    expect(Tag.find_by_name('come-up').mission_id).to be_nil
  end

  scenario 'clicking tag at top of question index page adds it to search', js: true do
    @question1.tags = [@tag1, @tag2, @tag3]
    visit "/en/m/#{@mission.compact_name}/questions"

    # First search for something else
    search_for('cheese')
    expect(page).not_to have_content(@question2.code)

    # Click tag
    first('li', text: 'awesome').click
    expect(current_url).to include 'search=cheese+tag%253Aawesome'
    expect(page).to have_content(@question1.code)
    expect(page).not_to have_content(@question2.code)

    # Click another tag
    first('li', text: 'twenty dollaz').click
    expect(current_url).to include 'search=cheese+tag%253A%2522twenty+dollaz%2522'
    expect(current_url).not_to include 'awesome'
    expect(page).to have_content(@question1.code)
    expect(page).not_to have_content(@question2.code)

    # More complicated searches
    search_for('tag: (awesome |thriftshop )cheese')
    first('li', text: 'awesome').click
    expect(current_url).to include 'search=cheese+tag%253Aawesome'

    search_for('cheese tag: "twenty dollaz"')
    first('li', text: 'awesome').click
    expect(current_url).to include 'search=cheese+tag%253Aawesome'
  end
end
