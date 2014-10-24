require "spec_helper"

feature "questions flow" do
  before do
    @question1 = create(:question, name: "How many cheeses?")
    @question2 = create(:question, name: "How many wines?")
    @user = get_user
    # @user = create(:user, role_name: 'coordinator')
    login(@user)
  end

  scenario 'search' do
    visit "/en/m/#{get_mission.compact_name}/questions"
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
    create(:tag, name: "thriftshop", mission_id: get_mission.id)
    create(:tag, name: "twenty", mission_id: get_mission.id)
    create(:tag, name: "dollaz", mission_id: get_mission.id)
    create(:tag, name: "pop", mission_id: nil)

    visit "/en/m/#{get_mission.compact_name}/questions/#{@question1.id}/edit"
    expect(page).to have_content "Tags:"

    # Mission tags
    fill_in "token-input-question_tag_ids", with: "t"
    expect(page).to have_content "thriftshop"
    expect(page).to have_content "twenty"

    fill_in "token-input-question_tag_ids", with: "th"
    expect(page).to have_content "thriftshop"
    expect(page).not_to have_content "twenty"
    expect(page).to have_content "th [New tag]"

    # Apply tag
    find('li', text: "thriftshop").click

    # Standard tag
    fill_in "token-input-question_tag_ids", with: "p"
    expect(page).to have_content "pop"
    find('li', text: "pop").click

    # Create a new tag
    fill_in "token-input-question_tag_ids", with: "pocket"
    find('li', text: "pocket").click

    click_button "Save"

    # New tags show on index page (not yet)
    # expect(page).to have_content "Questions"
    # expect(page).to have_content "thriftshop"
    # expect(page).to have_content "pocket"

    # New tags show on question page
    visit "/en/m/#{get_mission.compact_name}/questions/#{@question1.id}"
    expect(page).to have_content "thriftshop"
    expect(page).to have_content "pop"
    expect(page).to have_content "pocket"
  end
end
