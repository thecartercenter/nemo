# frozen_string_literal: true

require "rails_helper"

feature "enketo form rendering and submission", js: true do
  let(:user) { create(:user) }
  let(:form) { create(:form, :live, question_types: %w[text]) }
  let(:params) do
    {locale: "en", mode: "m", mission_name: get_mission.compact_name,
     form_id: form.id, enketo: 1}
  end

  let(:r1) { create(:response, form: form, answer_values: %w[foo]) }

  before do
    login(user)
  end

  it "renders" do
    visit(new_response_path(params))
    expect(page).to have_content(form.name)
    expect(page).to have_content(form.c[0].name)
  end
end
