require "spec_helper"

describe "Question search form", type: :feature do
  before do
    @questions = create_list(:question, 2, name: "Walden")
    @question = create(:question)
    @user = get_user
    login(@user)
    visit "/en/m/#{get_mission.compact_name}/questions"
  end
  subject { page }

  context "basic search" do
    before { search_for 'wald' }
    it { should have_content "Displaying all 2 Questions" }
    it { should have_content @questions[0].code }
    it { should have_content @questions[1].code }
  end

  context "no results" do
    before { search_for 'boogeyman' }
    it { should have_content "No Questions found" }
  end

  context "empty search" do
    before { search_for '' }
    it { should have_content "Displaying all 3 Questions" }
  end

  context "search error" do
    before { search_for 'creepy:' }
    it { should have_content "Error: Your search query could not be understood due to unexpected text near the end." }
  end

  def search_for(query)
    fill_in "search", with: query
    click_button "Search"
  end
end