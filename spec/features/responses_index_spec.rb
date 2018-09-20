require "spec_helper"

feature "responses index" do
  context "general index page display" do
    let(:user) { create(:user) }
    let!(:form) { create(:form, :published, name: "TheForm") }

    before do
      login(user)
    end

    scenario "returning to index after response loaded via ajax", js: true do
      visit("/en/m/#{get_mission.compact_name}/responses")
      expect(page).not_to have_content("TheForm")

      # Create response and make it show up via AJAX
      response = create(:response, form: form)
      page.execute_script("responses_fetch();")
      expect(page).to have_content("TheForm")

      # Click response and then go back. Should still be there!
      click_link(response.shortcode.downcase)
      click_link("Responses")
      expect(page).to have_content("TheForm")
    end
  end

  describe "batch delete", js: true do
    let(:admin) { create(:admin) }
    let(:mission) { get_mission }
    let!(:responses) { create_list(:response, 3, mission: mission) }

    before do
      login(admin)
    end

    scenario "works" do
      visit("/en/m/#{mission.compact_name}/responses")
      all("input.batch_op").each { |b| b.set(true) }
      accept_confirm { click_on("Delete Selected") }
      expect(page).to have_content("3 responses deleted successfully")
    end
  end
end
