# frozen_string_literal: true

require "rails_helper"

# Doing this on purpose here for parallel structure.
# rubocop:disable Style/BracesAroundHashParameters

# The QuestionWarner is the most complex of the warners, so we just test this one as a way
# of testing the base class, which is where most of the code is.
describe Forms::IntegrityWarnings::QuestionWarner do
  subject(:warner) { described_class.new(question) }

  context "with fresh question" do
    let(:question) { create(:question) }

    it "returns no warnings" do
      expect(warner.warnings(:careful_with_changes)).to be_empty
      expect(warner.warnings(:features_disabled)).to be_empty
    end
  end

  context "with in-use, published question" do
    let(:form1) { create(:form, :live, name: "Form 1", question_types: %w[text]) }
    let(:extra_forms) { [create(:form, name: "Form 2"), create(:form, name: "Form 3")] }
    let(:question) { form1.c[0].question }

    before do
      extra_forms.each do |form|
        create(:questioning, form: form, parent: form.root_group, question: question)
      end
    end

    context "with no responses" do
      context "with three forms" do
        it "returns warnings" do
          expect(warner.warnings(:careful_with_changes)).to contain_exactly(
            {reason: :published, i18n_params: nil},
            {reason: :in_use, i18n_params: {form_list: "Form 1, Form 2, Form 3"}}
          )
          expect(warner.warnings(:features_disabled)).to contain_exactly(
            {reason: :published, i18n_params: nil}
          )
        end
      end

      context "with four forms" do
        let(:extra_forms) do
          [create(:form, name: "Form 2"), create(:form, name: "Form 3"), create(:form, name: "Form 4")]
        end

        it "returns warning with truncated form list" do
          expect(warner.warnings(:careful_with_changes)).to contain_exactly(
            {reason: :published, i18n_params: nil},
            {reason: :in_use, i18n_params: {form_list: "Form 1, Form 2, Form 3 (+1 more)"}}
          )
        end
      end
    end
  end

  context "with question with data" do
    let(:form) { create(:form, name: "Form 1", question_types: %w[text]) }
    let(:question) { form.c[0].question }
    let!(:response) { create(:response, form: form, answer_values: %w[x]) }

    it "returns warnings" do
      expect(warner.warnings(:careful_with_changes)).to contain_exactly(
        {reason: :in_use, i18n_params: {form_list: "Form 1"}}
      )
      expect(warner.warnings(:features_disabled)).to contain_exactly(
        {reason: :data, i18n_params: nil}
      )
    end
  end

  context "with standard question" do
    let(:question) { create(:question, :standard) }

    it "returns warnings" do
      expect(warner.warnings(:careful_with_changes)).to be_empty
      expect(warner.warnings(:features_disabled)).to be_empty
    end
  end

  context "with standard copy question" do
    let(:standard) { create(:question, :standard) }
    let(:question) { standard.replicate(mode: :to_mission, dest_mission: get_mission) }

    it "returns warnings" do
      expect(warner.warnings(:careful_with_changes)).to contain_exactly(
        {reason: :standard_copy, i18n_params: nil}
      )
      expect(warner.warnings(:features_disabled)).to contain_exactly(
        {reason: :standard_copy, i18n_params: nil}
      )
    end
  end
end

# rubocop:enable Style/BracesAroundHashParameters
