# There are more report tests in test/unit/report.
require 'spec_helper'

describe Report::StandardFormReport do
  before do
    @form = create(:form, question_types: %w(select_one integer))
    @report = create(:standard_form_report, form: @form, disagg_qing: @form.questionings[1])
  end

  it 'should have disagg_qing nullified when questioning destroyed' do
    @form.questionings[1].destroy
    expect(@report.reload.disagg_qing).to be_nil
  end

  it 'should be destroyed when form destroyed' do
    @form.destroy
    expect(Report::Report.exists?(@report)).to be false
  end
end
