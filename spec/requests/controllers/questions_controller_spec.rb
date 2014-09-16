require "spec_helper"

describe "Question search form", type: :feature do
  before do
    @questions = create_list(:question, 2, name: "Walden")
    @question = create(:question)
    @user = get_user
    login(@user)
    visit "/en/m/#{get_mission.compact_name}/questions"
  end

  it "should search questions" do
    fill_in "search", with: "wald"
    click_button "Search"
    expect(page).to have_content "Displaying all 2 Questions"
    expect(page).to have_content @questions[0].code
    expect(page).to have_content @questions[1].code
  end
end