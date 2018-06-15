require "rails_helper"

feature "forms flow", js: true do
  let!(:user) { create(:user) }
  let!(:form) { create(:sample_form) }
  let(:forms_path) { "/en/m/#{form.mission.compact_name}/forms" }

  before do
    login(user)
  end

  describe "print from index" do
    scenario "should work and show tip the first time" do
      visit(forms_path)

      # First time printing should show tips.
      find('a.print-link').click
      expect(page).to have_css('h4', text: 'Print Format Tips')
    end

    # Couldn't get this spec to work on headless chrome. Maybe it will work later.
    # context "with shown flag set" do
    #   scenario "should not show tip" do
    #     visit(forms_path)
    #     expect(page).to have_content('Form')
    #     date = Date.today.strftime("%Y-%m-%d")
    #     page.execute_script("window.localStorage.setItem('form_print_format_tips_shown', '#{date}')")
    #
    #     # Second time printing should not show tips.
    #     find('a.print-link').click
    #     expect(page).not_to have_css('h4', text: 'Print Format Tips')
    #   end
    # end
  end
end
