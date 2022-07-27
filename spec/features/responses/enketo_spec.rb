# frozen_string_literal: true

require "rails_helper"

feature "enketo form rendering and submission", js: true do
  let(:user) { create(:user) }
  let(:form) { create(:form, :live, question_types: %w[text]) }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, enketo: 1} }
  let(:form_params) { params.merge(form_id: form.id) }
  let(:response_params) { params.merge(id: r1.shortcode) }
  let(:r1) { create(:response, form: form, answer_values: %w[foo-bar]) }

  before do
    login(user)
  end

  it "renders blank" do
    visit(new_response_path(form_params))
    expect(page).to have_content(form.name)
    expect(page).to have_content(form.c[0].name)
  end

  it "shows existing response" do
    visit(response_path(response_params))
    expect(page).to have_content(form.name)
    expect(page).to have_content(form.c[0].name)
    expect(page).to have_content("foo-bar")
  end
end
