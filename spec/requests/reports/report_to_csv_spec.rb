require 'spec_helper'

describe "report CSV output" do

  before do
    user = create(:user, role_name: 'coordinator')
    login(user)
  end

  it "should work for grid-type report" do
    form = create(:form, question_types: %w(select_one))
    create_list(:response, 2, form: form, answer_values: %w(Cat))
    create_list(:response, 3, form: form, answer_values: %w(Dog))
    report = create(:answer_tally_report, _calculations: [form.questions[0]])
    get("/en/m/#{form.mission.compact_name}/reports/#{report.id}.csv")
    expect(response).to be_success
    expect(response.body).to eq %Q{"",Cat,Dog\r\n#{form.questions[0].name},2,3\r\n}
  end

  it "should properly format long text" do
    form = create(:form, question_types: %w(text long_text))
    qs = form.questions
    create(:response, form: form,
      answer_values: ["Foo", "Some\n<strong>long</strong><br/><ol><li>text</li><li>stuff&nbsp;&amp;stuff</li></ol>"])
    report = create(:list_report, _calculations: qs)
    get("/en/m/#{form.mission.compact_name}/reports/#{report.id}.csv")
    expect(response).to be_success
    expect(response.body).to eq %Q{#{qs[0].name},#{qs[1].name}\r\nFoo,\"Some **long**\r\n\r\n1. text\r\n2. stuff&stuff\"\r\n}
  end
end
