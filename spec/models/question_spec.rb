require 'rails_helper'

describe Question do
  describe ".not_in_form" do
    let!(:form) { create(:form, question_types: %w(integer integer)) }
    let!(:other_question) { create(:question) }

    it "should work" do
      expect(Question.not_in_form(form).all).to eq([other_question])
    end
  end

  describe "#min_max_error_msg" do
    let(:question) { build(:question, qtype_name: 'integer',
      minimum: 10, maximum: 20, minstrictly: false, maxstrictly: true) }

    it "is correct" do
      expect(question.min_max_error_msg).to eq("Must be greater than or equal to 10 and less than 20")
    end
  end

  describe "normalization" do
    let(:question) { create(:question, submitted) }
    subject { submitted.keys.map { |k| [k, question.send(k)] }.to_h }

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
