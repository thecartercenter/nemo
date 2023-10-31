# frozen_string_literal: true

require "rails_helper"
require "fileutils"
require "zip"

feature "xlsform export" do
  context "single form" do
    let(:user) { create(:user, role_name: "coordinator") }
    let(:form) { create(:form, name: "Export Test", question_types: %w[text]) }

    before do
      login(user)
    end

    it "exports to XLSForm successfully" do
      visit(form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))
      click_link("Export XLSForm")

      expect(page.current_url).to match("export_xls")
      expect(page.body).to match(form.name.to_s)
      expect(page.body).to match("text")
    end
  end
end
