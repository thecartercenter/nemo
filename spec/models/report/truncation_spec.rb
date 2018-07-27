require 'rails_helper'

describe "report truncation" do
  include_context "reports"

  shared_examples_for "a truncatable report" do
    before do
      stub_const("Report::Gridable::RESPONSES_QUANTITY_LIMIT", 3)
      report.run
    end

    context "with too many rows to display" do
      let(:response_count) { 4 }

      it "should limit returned rows to 3 and set truncated flag" do
        expect(report.data.rows.size).to eq 3
        expect(report.data.truncated).to be true
      end
    end

    context "without too many rows to display" do
      let(:response_count) { 2 }

      it "should limit returned rows to 2 and not set truncated flag" do
        expect(report.data.rows.size).to eq 2
        expect(report.data.truncated).to be false
      end
    end
  end

  describe Report::ListReport, :reports do
    let(:form) { create(:form, question_types: %w(integer integer)) }
    let(:report) do
      create(:list_report, calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
        {rank: 2, type: "Report::IdentityCalculation", question1_id: form.questions[0].id},
        {rank: 3, type: "Report::IdentityCalculation", question1_id: form.questions[1].id}
      ])
    end
    let!(:responses) { create_list(:response, response_count, form: form, answer_values: %w(123 456)) }

    it_behaves_like "a truncatable report"
  end

  describe Report::ResponseTallyReport, :reports do
    let(:form) { create(:form, question_types: %w(integer)) }
    let(:report) do
      create(:response_tally_report, calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", question1_id: form.questions[0].id}
      ])
    end

    # Create N responses with distinct answers. Each response will therefore give rise to one row in the
    # computed report.
    before do
      response_count.times do |i|
        create(:response, form: form, answer_values: [(i * 100).to_s])
      end
    end

    it_behaves_like "a truncatable report"
  end
end
