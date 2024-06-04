# frozen_string_literal: true

require "rails_helper"
require "fileutils"
require "zip"

describe "form export" do
  context "single form" do
    let(:user) { create(:user, role_name: "coordinator") }
    let(:form) { create(:form, :live, question_types: %w[text]) }

    before do
      login(user)
      ODK::FormRenderJob.perform_now(form)
    end

    it "XML exports successfully" do
      visit(form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))
      click_link("Export XML")
      expect(page.body).to match("<h:title>#{form.name}</h:title>")
    end

    it "XLSForm exports successfully" do
      visit(form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))
      click_link("Export XLSForm")

      expect(page.current_url).to match("export_xls")
      expect(page.body).to match(form.name.to_s)
      expect(page.body).to match("text")
    end
  end

  context "multiple forms" do
    let(:user) { create(:user, role_name: "coordinator") }
    let(:form1) { create(:form, :live, question_types: %w[text]) }
    let(:form2) { create(:form, :draft, question_types: %w[text]) } # Draft should not be exported
    let(:form3) { create(:form, :paused, question_types: %w[text]) }

    before do
      login(user)
      ODK::FormRenderJob.perform_now(form1)
      ODK::FormRenderJob.perform_now(form3)
    end

    it "XML exports successfully" do
      visit(forms_path(locale: "en", mode: "m", mission_name: get_mission.compact_name))
      click_link("Export XML")

      Zip::File.open_buffer(page.body) do |zipfile|
        expect(zipfile.count).to be(2)
        zipfile.each do |file|
          expect(file.get_input_stream.read).to match("<h:title>.+</h:title>")
        end
      end
    end
  end
end
