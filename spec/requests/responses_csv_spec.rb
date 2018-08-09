# frozen_string_literal: true

require "rails_helper"

describe "responses csv", :csv, type: :request do
  let(:form) { create(:form, :published, question_types: %w[integer multilevel_select_one]) }
  let!(:response1) { create(:response, form: form, answer_values: [2, %w[Animal]]) }
  let!(:response2) { create(:response, form: form, answer_values: [15, %w[Plant]]) }
  let(:user) { create(:user) }
  let(:result) { CSV.parse(response.body) }

  it "should produce valid CSV" do
    login(user)
    get_s(responses_path(mode: "m", mission_name: get_mission.compact_name, format: :csv))
    expect(response.headers["Content-Disposition"]).to match(
      /attachment; filename="elmo-#{get_mission.compact_name}-responses-\d{4}-\d\d-\d\d-\d{4}.csv"/
    )
    expect(result.size).to eq 3 # 2 response rows, 1 header row
    expect(result[1][10]).to eq "Animal"
    expect(result[2][10]).to eq "Plant"
  end
end
