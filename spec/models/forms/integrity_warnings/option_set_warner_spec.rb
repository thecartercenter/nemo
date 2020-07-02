# frozen_string_literal: true

require "rails_helper"

# See QuestionWarner for more rigorous specs.
describe Forms::IntegrityWarnings::OptionSetWarner do
  subject(:warner) { described_class.new(option_set) }

  context "with in-use, published option_set", :reset_factory_sequences do
    let(:form) do
      create(:form, :live, question_types: %w[select_one select_one select_one select_one])
    end
    let(:option_set) { form.c[0].option_set }

    before do
      form.children.each do |child|
        child.update!(option_set: option_set)
      end
    end

    context "with four forms" do
      it "returns warning with truncated form list" do
        expect(warner.warnings(:careful_with_changes)).to contain_exactly(
          {reason: :published, i18n_params: nil},
          {reason: :in_use, i18n_params: {question_list: "SelectOneQ1, SelectOneQ2, SelectOneQ3 (+1 more)"}}
        )
      end
    end
  end
end
