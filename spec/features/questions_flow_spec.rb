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

  scenario 'tag add/remove', js: true do
    create(:tag, name: "thriftshop")
    create(:tag, name: "twenty")
    create(:tag, name: "dollaz")

    visit "/en/m/#{get_mission.compact_name}/questions/#{@question1.id}/edit"
    expect(page).to have_content "Tags"

    fill_in "Tags", with: "t"
    expect(page).to have_content "thriftshop"
    expect(page).to have_content "twenty"

    fill_in "Tags", with: "th"
    expect(page).to have_content "thriftshop"
    expect(page).not_to have_content "twenty"

    # Apply tag
    click_link "thriftshop"

    # Create a new tag
    fill_in "Tags", with: "pocket"
    click_link "pocket"

    click_button "Save"

    # New tags show on index page
    expect(page).to have_content "Questions"
    expect(page).to have_content "thriftshop"
    expect(page).to have_content "pocket"

    # New tags show on question page
    visit question_path(@question1)
    expect(page).to have_content "thriftshop"
    expect(page).to have_content "pocket"
  end
end
