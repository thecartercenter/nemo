# There are more report tests in test/unit/report.
require 'rails_helper'

# This spec covers behavior common to all gridable report types.
describe Report::Gridable do
  before do
    @form = create(:form, question_types: %w(select_one integer text))
  end

  describe "cache_key" do
    before do
      @report = create(:list_report, _calculations: ['submitter', 'source'])
    end

    it "should be correct" do
      expect(@report.cache_key).to match(
        %r{\Areport/list_reports/(.+)/calcs-2-/report/identity_calculations/(.+)\z})
    end
  end

  context 'calculation destruction' do
    before do
      @report = create(:list_report, _calculations: ['submitter', 'source'])
    end

    it 'should reorder ranks' do
      @report.calculations[0].destroy
      expect(@report.reload.calculations[0].rank).to eq 1
    end
  end

  context 'when calculation question destroyed' do
    before do
      # Create a ListReport with three calculations, then destroy the question.
      @report = create(:list_report, _calculations: [@form.questions[0], 'submitter', 'source'])
      @form.questions[0].destroy
    end

    it 'should lose calculation and fix other calculations' do
      @report.reload
      expect(@report.calculations.map(&:attrib1_name)).to eq %w(submitter source)
      expect(@report.calculations.map(&:rank)).to eq [1,2]
    end
  end

  context 'when last calculations question destroyed' do
    before do
      @report = create(:list_report, _calculations: [@form.questions[0]])
      @form.questions[0].destroy
    end

    it 'should destroy self' do
      expect(Report::Report.exists?(@report.id)).to be false
    end
  end
end
