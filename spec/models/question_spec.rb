# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: questions
#
#  id                :uuid             not null, primary key
#  access_level      :string(255)      default("inherit"), not null
#  auto_increment    :boolean          default(FALSE), not null
#  canonical_name    :text             not null
#  code              :string(255)      not null
#  hint_translations :jsonb
#  key               :boolean          default(FALSE), not null
#  maximum           :decimal(15, 8)
#  maxstrictly       :boolean
#  metadata_type     :string
#  minimum           :decimal(15, 8)
#  minstrictly       :boolean
#  name_translations :jsonb            not null
#  qtype_name        :string(255)      not null
#  reference         :string
#  standard_copy     :boolean          default(FALSE), not null
#  text_type_for_sms :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :uuid
#  option_set_id     :uuid
#  original_id       :uuid
#
# Indexes
#
#  index_questions_on_mission_id           (mission_id)
#  index_questions_on_mission_id_and_code  (mission_id,code) UNIQUE
#  index_questions_on_option_set_id        (option_set_id)
#  index_questions_on_original_id          (original_id)
#  index_questions_on_qtype_name           (qtype_name)
#
# Foreign Keys
#
#  questions_mission_id_fkey     (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  questions_option_set_id_fkey  (option_set_id => option_sets.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe Question do
  describe ".not_in_form" do
    let!(:form) { create(:form, question_types: %w[integer integer]) }
    let!(:other_question) { create(:question) }

    it "should work" do
      expect(Question.not_in_form(form).all).to eq([other_question])
    end
  end

  describe "#min_max_error_msg" do
    let(:question) do
      build(:question, qtype_name: "integer",
                       minimum: 10, maximum: 20, minstrictly: false, maxstrictly: true)
    end

    it "is correct" do
      expect(question.min_max_error_msg).to eq("Must be greater than or equal to 10 and less than 20")
    end
  end

  describe "normalization" do
    let(:question) { create(:question, submitted) }
    subject { submitted.keys.index_with { |k| question.send(k) }.to_h }

    describe "min max constraints" do
      shared_examples_for "minmax" do |prefix|
        let(:val) { :"#{prefix}imum" }
        let(:strict) { :"#{prefix}strictly" }

        context do
          let(:submitted) { {qtype_name: "integer", val => 4, strict => nil} }
          it { is_expected.to eq(qtype_name: "integer", val => 4, strict => false) }
        end

        context do
          let(:submitted) { {qtype_name: "integer", val => 4, strict => false} }
          it { is_expected.to eq(qtype_name: "integer", val => 4, strict => false) }
        end

        context do
          let(:submitted) { {qtype_name: "integer", val => 4, strict => true} }
          it { is_expected.to eq(qtype_name: "integer", val => 4, strict => true) }
        end

        context do
          let(:submitted) { {qtype_name: "integer", val => nil, strict => nil} }
          it { is_expected.to eq(qtype_name: "integer", val => nil, strict => nil) }
        end

        context do
          let(:submitted) { {qtype_name: "integer", val => nil, strict => false} }
          it { is_expected.to eq(qtype_name: "integer", val => nil, strict => nil) }
        end

        context do
          let(:submitted) { {qtype_name: "integer", val => nil, strict => true} }
          it { is_expected.to eq(qtype_name: "integer", val => nil, strict => nil) }
        end

        context do
          let(:submitted) { {qtype_name: "integer", val => "", strict => true} }
          it { is_expected.to eq(qtype_name: "integer", val => nil, strict => nil) }
        end

        context do
          let(:submitted) { {qtype_name: "text", val => 5, strict => true} }
          it { is_expected.to eq(qtype_name: "text", val => nil, strict => nil) }
        end
      end

      it_behaves_like "minmax", "min"
      it_behaves_like "minmax", "max"
    end

    describe "qtype and metadata" do
      context do
        let(:submitted) { {qtype_name: "datetime", metadata_type: "formstart"} }
        it { is_expected.to eq(qtype_name: "datetime", metadata_type: "formstart") }
      end

      context do
        let(:submitted) { {qtype_name: "datetime", metadata_type: ""} }
        it { is_expected.to eq(qtype_name: "datetime", metadata_type: nil) }
      end

      context do
        let(:submitted) { {qtype_name: "date", metadata_type: "formstart"} }
        it { is_expected.to eq(qtype_name: "date", metadata_type: nil) }
      end
    end
  end

  describe "validations" do
    describe "reference url" do
      let(:question) { build(:question, reference: ref) }

      context "with valid reference" do
        let(:ref) { "https://example.org/parts/6" }
        it "has a valid reference" do
          expect(question).to be_valid
        end
      end

      context "with valid reference" do
        let(:ref) { "http://example.org/parts/6" }
        it "has a valid reference" do
          expect(question).to be_valid
        end
      end

      context "with invalid reference" do
        let(:ref) { "www.blah" }
        it "has an invalid reference" do
          expect(question).not_to be_valid
          expect(question.errors[:reference].join).to match(/must begin with https/)
        end
      end
    end

    describe "code format" do
      let(:question) { build(:question, code: code) }

      context "with invalid code" do
        let(:code) { "a b" }

        it "errors for format" do
          expect(question).not_to be_valid
          expect(question.errors[:code].join).to match(/Should start with a letter/)
        end
      end

      context "with blank code" do
        let(:code) { "" }

        it "errors for presence" do
          expect(question).not_to be_valid
          expect(question.errors[:code].join).to match(/is required/)
        end
      end
    end

    describe "option set presence" do
      let(:question) { build(:question, qtype_name: "select_one", option_set: nil) }

      it "is enforced" do
        expect(question).not_to be_valid
        expect(question.errors[:option_set].join).to match(/is required/)
      end
    end
  end
end
