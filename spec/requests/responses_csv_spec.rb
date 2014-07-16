require 'spec_helper'

describe 'Responses CSV' do
  before :all do
    form = create :form, :question_types => %w(integer select_one), :option_names => %w(Yes No)
    create :response, :form => form, :_answers => %w(2 No)
    create :response, :form => form, :_answers => %w(15 Yes)
    login(get_user)
  end

  it 'should produce valid CSV' do
    get responses_path mode: 'm', mission_name: get_mission.compact_name, format: :csv
    expect(response.headers['Content-Disposition']).to match(
      /attachment; filename="elmo-#{get_mission.compact_name}-responses-\d{4}-\d\d-\d\d-\d{4}.csv"/)
    result = CSV.parse(response.body)
    expect(result.size).to eq 5 # 4 answer rows, 1 header row
    expect(result[0].size).to eq 15
  end
end
