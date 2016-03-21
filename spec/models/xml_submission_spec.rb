require 'spec_helper'

describe XMLSubmission do
  include ODKSubmissionSupport

  before do
    @form = create(:form, question_types: ['integer', ['integer', 'integer']])
    @form.publish!
    @response = create(:response, form: @form)
    @files = { xml_submission_file: StringIO.new(build_odk_submission(@form, repeat: true)) }
  end

  describe '.new' do
    it 'creates a submission and parses it to populate response' do
      submission = XMLSubmission.new(response: @response, files: @files, source: 'odk')
      response = submission.response
      response.answers.each_with_index do |answer|
        expect(answer.inst_num).to eq nil unless answer.from_group?
      end
      expect(response.answers.where('inst_num > ?', 1).count).to eq 2
      expect(response).to be_valid
    end
  end
end
