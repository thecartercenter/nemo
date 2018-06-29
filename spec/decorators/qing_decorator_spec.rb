require "rails_helper"

describe QuestioningDecorator do
  describe "display_if" do
    let(:form) { create(:form, question_types: %w(integer integer integer integer)) }
    let(:qing) { form.c.last }
    let(:decorated_qing) { qing.decorate }

    context "concatenated_conditions" do
      let(:decorated_conditions) do [
        instance_double(ConditionDecorator, human_readable: 'foo'),
        instance_double(ConditionDecorator, human_readable: 'bar'),
        instance_double(ConditionDecorator, human_readable: 'baz')
      ] end

      before do
        expect(decorated_qing).to receive(:decorated_conditions).and_return(decorated_conditions)
      end

      context "display_if is all_met" do
        it "displays with all and" do
          decorated_qing.update_attribute(:display_if, "all_met")

          expected = "foo AND bar AND baz"
          expect(decorated_qing.concatenated_conditions).to eq expected
        end
      end

      context "display_if is any_met" do
        it "displays with all or" do
          decorated_qing.update_attribute(:display_if, "any_met")

          expected = "foo OR bar OR baz"
          expect(decorated_qing.concatenated_conditions).to eq expected
        end
      end
    end

    context "only one condition" do
      let(:decorated_conditions) do [
        instance_double(ConditionDecorator, human_readable: 'foo')
      ] end

      before do
        decorated_qing.update_attribute(:display_if, "all_met")

        expect(decorated_qing).to receive(:decorated_conditions).and_return(decorated_conditions)
      end

      it "returns only condition" do
        expect(decorated_qing.concatenated_conditions).to eq "foo"
      end
    end
  end
end
