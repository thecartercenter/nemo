# frozen_string_literal: true

require "rails_helper"

describe Results::AnswerDecorator do
  describe "#shortened" do
    let(:form) { create(:form, question_types: [qtype]) }
    let(:answer) { build(:answer, answer_attribs.merge(form_item: form.c[0])) }
    subject(:shortened) { described_class.new(answer).shortened }

    context "decimal value" do
      let(:qtype) { "decimal" }
      let(:answer_attribs) { {value: "123.28397928347392"} }
      it { is_expected.to eq("123.28") }
    end

    context "text values" do
      shared_examples_for "text" do
        let(:answer_attribs) { {value: "Some very <script>very</script> very very very very very long text"} }
        it { is_expected.to eq("Some very very very very very...") }
      end

      context "long_text" do
        let(:qtype) { "long_text" }
        it_behaves_like "text"
      end

      context "text" do
        let(:qtype) { "text" }
        it_behaves_like "text"
      end
    end

    context "datetime value" do
      let(:qtype) { "datetime" }

      context "with value" do
        let(:answer_attribs) { {datetime_value: "2012-01-01 12:34:56"} }
        it { is_expected.to eq("2012-01-01 12:34:56") }
      end

      context "nil value" do
        let(:answer_attribs) { {datetime_value: nil} }
        it { is_expected.to be_nil }
      end
    end
  end
end
