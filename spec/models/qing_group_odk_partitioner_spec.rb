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
      results = QingGroupOdkPartitioner.new(form_questions_with_multilevel).fragment

      expect(results.size).to eq(1)
      expect(results.keys[0]).to be_a QingGroup
      expect(results.values[0]).to be_a Hash
      expect(results.values[0].keys.map(&:class)).to eq [QingGroupFragment, QingGroupFragment, QingGroupFragment]
    end

    it "doesn't create new groups if there isn't a multilevel question on it" do
      results = QingGroupOdkPartitioner.new(form_questions).fragment

      expect(results.size).to eq(1)
      expect(results.keys[0]).to be_a QingGroup
      expect(results.values[0]).to be_a Hash
      expect(results.values[0].keys[0]).to be_a QingGroupFragment
      expect(results.values[0].values[0]).to be_a Hash
      expect(results.values[0].values[0].keys.map(&:class)).to eq [Questioning, Questioning]
    end

    it "leaves questionings outside groups untouched" do
      results = QingGroupOdkPartitioner.new(form_questions_without_groups).fragment

      expect(results.size).to equal(2)
      expect(results.keys.map(&:class)).to eq [Questioning, Questioning]
    end
  end

  def organize_form_questions(form_questions)

  end

end
