require "spec_helper"

feature "questions flow" do
  before do
    @mission = get_mission

    @question1 = create(:question, name: "How many cheeses?")
    @question2 = create(:question, name: "How many wines?")

    @tag1 = create(:tag, name: "thriftshop", mission_id: @mission.id)
    @tag2 = create(:tag, name: "twenty dollaz", mission_id: @mission.id)
    @tag3 = create(:tag, name: "awesome", mission_id: nil, is_standard: true) # Standard tag

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

  scenario 'tag add/remove', js: true, driver: :selenium do
    visit "/en/m/#{@mission.compact_name}/questions/#{@question1.id}/edit"
    expect(page).to have_content "Tags:"

    # Mission tags
    fill_in "token-input-question_tag_ids", with: "t"
    expect(page).to have_content "thriftshop"
    expect(page).to have_content "twenty dollaz"

    fill_in "token-input-question_tag_ids", with: "th"
    expect(page).to have_content "thriftshop"
    expect(page).not_to have_content "twenty dollaz"
    expect(page).to have_content "th [New tag]"

    # Apply tag
    find('li', text: "thriftshop").click

    # Standard tag
    fill_in "token-input-question_tag_ids", with: "a"
    expect(page).to have_content "awesome"
    within find('li', text: 'awesome') do
      expect(page).to have_selector 'i.fa-certificate'
    end
    # Apply
    find('li', text: "awesome").click

    # Create a new tag
    fill_in "token-input-question_tag_ids", with: "in my pocket"
    find('li', text: "in my pocket").click

    # Add and then cancel a new tag
    fill_in "token-input-question_tag_ids", with: "pop"
    find('li', text: "pop").click
    within find('div#tag_ids li', text: "pop") do
      find('span.token-input-delete-token-elmo').click # "x" close button
    end
    expect(page).not_to have_content "pop"

    click_button "Save"

    # New tag should be in database
    expect(Tag.find_by_name('in my pocket').mission_id).to eq @mission.id
    # Canceled tag should not
    expect(Tag.pluck(:name)).not_to include('pop')

    # Tags show on index page (twice - once at top and once in question's row)
    expect(page).to have_content "Questions"
    expect(page).to have_selector 'li', text: "thriftshop", count: 2
    expect(page).to have_selector 'li', text: "awesome", count: 2
    within first('li', text: 'awesome') do
      expect(page).to have_selector 'i.fa-certificate'
    end
    expect(page).to have_selector 'li', text: "in my pocket", count: 2
    within %{tr[id="question_#{@question1.id}"]} do
      expect(page).to have_selector 'li', text: "thriftshop"
      expect(page).to have_selector 'li', text: "awesome"
      within find('li', text: 'awesome') do
        expect(page).to have_selector 'i.fa-certificate'
      end
      expect(page).to have_selector 'li', text: "in my pocket"
    end

    # Tags show on question page
    visit "/en/m/#{@mission.compact_name}/questions/#{@question1.id}"
    within "div#tag_ids" do
      expect(page).to have_selector 'li', text: "thriftshop"
      expect(page).to have_selector 'li', text: "in my pocket"
      expect(page).to have_selector 'li', text: "awesome"
      within find('li', text: 'awesome') do
        expect(page).to have_selector 'i.fa-certificate'
      end
      expect(page).not_to have_selector 'li', text: "pop"
    end

    # Admin mode
    @question3 = create(:question, name: "How much beer?", is_standard: true, mission_id: nil)
    visit "/en/admin/questions/#{@question3.id}/edit"

    fill_in "token-input-question_tag_ids", with: "a"
    expect(page).to have_content "awesome"
    expect(page).not_to have_content "in my pocket" # Non-standard tag
    find('li', text: "awesome").click

    # Create a new tag
    fill_in "token-input-question_tag_ids", with: "newt"
    find('li', text: "newt").click

    click_button "Save"

    # Tags show on question page
    visit "/en/admin/questions/#{@question3.id}"
    within "div#tag_ids" do
      expect(page).to have_selector 'li', text: "awesome"
      within find('li', text: 'awesome') do
        expect(page).to have_selector 'i.fa-certificate'
      end
    end

    # Check that new tag is standard in DB
    expect(Tag.find_by_name('newt').is_standard).to be_truthy
    expect(Tag.find_by_name('newt').mission_id).to be_nil
  end

  scenario 'clicking tag at top of index page adds it to search', js: true do
    @question1.tags = [@tag1, @tag2, @tag3]
    visit "/en/m/#{@mission.compact_name}/questions"

    # First search for something else
    search_for('cheese')
    expect(page).not_to have_content(@question2.code)

    # Click tag
    first('li', text: 'awesome').click
    expect(current_url).to include 'search=cheese+tag%253A+awesome'
    expect(page).to have_content(@question1.code)
    expect(page).not_to have_content(@question2.code)

    # Click another tag
    first('li', text: 'twenty dollaz').click
    expect(current_url).to include 'search=cheese+tag%253A+%2522twenty+dollaz%2522'
    expect(current_url).not_to include 'awesome'
    expect(page).to have_content(@question1.code)
    expect(page).not_to have_content(@question2.code)

    # More complicated searches
    search_for('tag: (awesome |thriftshop )cheese')
    first('li', text: 'awesome').click
    expect(current_url).to include 'search=cheese+tag%253A+awesome'

    search_for('cheese tag: "twenty dollaz"')
    first('li', text: 'awesome').click
    expect(current_url).to include 'search=cheese+tag%253A+awesome'
  end
end
