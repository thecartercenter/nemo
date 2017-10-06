require "spec_helper"

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
      click_button('OK')

      # Should show, then hide the loading indicator.
      expect(page).to have_css('#glb-load-ind')
      expect(page).not_to have_css('#glb-load-ind')

      # Should still be on same page.
      expect(current_url).to end_with('forms')
    end

    context "with shown flag set" do
      before do
        date = Date.today.strftime("%Y-%m-%d")
        page.execute_script("window.localStorage.setItem('form_print_format_tips_shown', '#{date}')")
      end

      scenario "should not show tip", :investigate do
        visit(forms_path)

        # Second time printing should not show tips.
        find('a.print-link').click
        expect(page).not_to have_css('h4', text: 'Print Format Tips')
      end
    end
  end
end
