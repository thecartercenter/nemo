require 'spec_helper'

describe "report CSV output" do

  before do
    @user = create(:user, role_name: 'coordinator')
    login(@user)
  end

  it "should work for grid-type report" do
    @form = create(:form, question_types: %w(select_one))
    create_list(:response, 2, form: @form, answer_values: %w(Cat))
    create_list(:response, 3, form: @form, answer_values: %w(Dog))
    @report = create(:answer_tally_report, _calculations: [@form.questions[0]])
    get("/en/m/#{@form.mission.compact_name}/reports/#{@report.id}.csv")
    expect(response).to be_success
    expect(response.body).to eq %Q{"",Cat,Dog\n#{@form.questions[0].name},2,3\n}
  end
end
