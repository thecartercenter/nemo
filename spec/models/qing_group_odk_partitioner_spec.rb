require 'spec_helper'

describe QingGroupOdkPartitioner do

  let(:qing_group) { build_stubbed(:qing_group) }
  let(:qing_1) { build_stubbed(:questioning) }
  let(:qing_2) { build_stubbed(:questioning) }
  let(:multilevel_qing) { build_stubbed(:questioning) }

  let(:form_questions) do
    { qing_group => { qing_1 => '',
                      qing_2 => ''}
    }
  end

  let(:form_questions_with_multilevel) do
    { qing_group => { qing_1 => '',
                      multilevel_qing => '',
                      qing_2 => ''}
    }
  end

  let(:form_questions_without_groups) do
    { qing_1 => '',
      qing_2 => ''}
  end

  before do
    allow(multilevel_qing).to receive(:multilevel?) { true }
  end

  describe "#organize" do

    it "splits qing groups in order to remove multilevel questions from them" do
      results = organize_form_questions(form_questions_with_multilevel)

      expect(results.length).to equal(3)
      expect(results[0]).to be_a QingGroupFragment
      expect(results[1]).to be_a Questioning
      expect(results[2]).to be_a QingGroupFragment
    end

    it "doesn't create new groups if there isn't a multilevel question on it" do
      results = organize_form_questions(form_questions)

      expect(results.length).to equal(1)
      expect(results[0]).to be_a QingGroupFragment
    end

    it "leaves questionings outside groups untouched" do
      results = organize_form_questions(form_questions_without_groups)

      expect(results.length).to equal(2)
      expect(results[0]).to be_a Questioning
      expect(results[1]).to be_a Questioning
    end
  end

  def organize_form_questions(form_questions)
    qing_group_odk_partitioner = QingGroupOdkPartitioner.new(form_questions)
    form_questions_organized = qing_group_odk_partitioner.fragment()
    form_questions_organized.keys
  end

end
