# frozen_string_literal: true

require "rails_helper"

feature "forms", js: true do
  let(:user) { create(:user) }
  let(:form) do
    create(:form, name: "Foo", question_types: %w[integer multilevel_select_one select_one integer])
  end

  # Allow longer delays because specs were failing on CI.
  let(:longer_wait_time) { 120 }

  before do
    login(user)
  end

  shared_examples_for "shows tips and prints" do
    context "first time" do
      it "should work and show tip" do
        visit(url)
        page.execute_script("localStorage.removeItem('form_print_format_tips_shown')")
        using_wait_time(longer_wait_time) do
          find("a.print-link").click
          expect(page).to have_css("h4", text: "Print Format Tips")

          click_button("OK")
          wait_for_load

          # Should still be on same page.
          expect(current_url).to match(url)
        end
      end
    end

    context "with shown flag set" do
      it "should not show tip" do
        visit(url)
        date = Time.zone.today.strftime("%Y-%m-%d")
        page.execute_script("localStorage.setItem('form_print_format_tips_shown', '#{date}')")
        using_wait_time(longer_wait_time) do
          find("a.print-link").click
          wait_for_load
          expect(page).not_to have_css("h4", text: "Print Format Tips")
        end
      end
    end
  end

  describe "print from index" do
    let(:url) { "/en/m/#{form.mission.compact_name}/forms" }
    it_behaves_like "shows tips and prints"
  end

  describe "print from form show page" do
    let(:url) { "/en/m/#{form.mission.compact_name}/forms/#{form.id}" }
    it_behaves_like "shows tips and prints"
  end

  describe "print from form edit page" do
    let(:url) { "/en/m/#{form.mission.compact_name}/forms/#{form.id}/edit" }
    it_behaves_like "shows tips and prints"
  end

  context "when viewing print media" do
    let(:url) { "/en/m/#{form.mission.compact_name}/forms" }

    it "should have form title" do
      visit(url)

      using_wait_time(longer_wait_time) do
        find("a.print-link").click
        click_button("OK")
        wait_for_load
      end

      with_print_emulation do
        expect(page).to have_css("h1", text: "Foo")
      end
    end
  end
end
