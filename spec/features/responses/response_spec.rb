# frozen_string_literal: true

require "rails_helper"

feature "responses", js: true do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:form) { create(:form, :live, name: "Myform", question_types: question_types) }
  let(:response) { create(:response, user: user, form: form, answer_values: answer_values) }
  let(:url_prefix) { responses_path(mode: "m", mission_name: get_mission.compact_name, locale: "en") }
  let(:response_url) { "#{url_prefix}/#{response.shortcode}" }

  before do
    login(user)
  end

  context "with simple form" do
    let(:question_types) { %w[text integer] }
    let(:answer_values) { %w[foo 123] }

    it "renders" do
      visit(response_url)
      expect(page).to have_css("a", text: user.name)
      expect(page).to have_css("p", text: "foo")
      expect(page).to have_css("div", text: "123")
    end
  end

  context "with no questions" do
    let(:question_types) { %w[] }
    let(:answer_values) { %w[] }

    it "renders" do
      visit(response_url)
      expect(page).to have_css("a", text: user.name)
    end
  end
end
