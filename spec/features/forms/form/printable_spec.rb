# frozen_string_literal: true

require "rails_helper"

feature "forms", js: true do
  let!(:user) { create(:user) }
  let!(:form) do
    create(:form, name: "Foo", question_types: %w[integer multilevel_select_one select_one integer])
  end
  let(:forms_path) { "/en/m/#{form.mission.compact_name}/forms" }

  before do
    login(user)
  end

  describe "print from index" do
    context "first time" do
      before do
        visit(forms_path)
      end

      it "should work and show tip" do
        find("a.print-link").click
        expect(page).to have_css("h4", text: "Print Format Tips")
      end
    end

    context "with shown flag set" do
      before do
        visit(forms_path)

        date = Time.zone.today.strftime("%Y-%m-%d")
        page.execute_script("window.localStorage.setItem('form_print_format_tips_shown', '#{date}')")
      end

      it "should not show tip" do
        find("a.print-link").click
        expect(page).not_to have_css("h4", text: "Print Format Tips")
      end
    end
  end
end
