require "rails_helper"

module Odk
  describe ConditionGroupDecorator, :odk, :reset_factory_sequences, database_cleaner: :truncate do
    include_context "odk rendering"

    let(:result) { decorate(condition_group).to_odk }

    context "empty, non-negated condition group" do
      let(:condition_group) { Forms::ConditionGroup.new(true_if: "always", negate: false, members: [])}

      it "should return nil" do
        expect(result).to be_nil
      end
    end

    # This is what will be returned from a skip rule set to skip_if = always.
    context "empty, negated condition group" do
      let(:condition_group) { Forms::ConditionGroup.new(true_if: "always", negate: true, members: [])}

      it "should return false" do
        expect(result).to eq "false()"
      end
    end

    context "non-nested condition group all true" do
      let(:condition_group) { Forms::ConditionGroup.new(true_if: "all_met", negate: false, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")
      ]) }

      it "concatenates with and" do
        expect(result).to eq "(a) and (b) and (c)"
      end
    end

    context "non-nested condition group negated" do
      let(:condition_group) { Forms::ConditionGroup.new(true_if: "all_met", negate: true, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")
      ])}

      it "adds the xpath not function" do
        expect(result).to eq "not((a) and (b) and (c))"
      end
    end

    context "non-nested condition group with any true" do
      let(:condition_group) { Forms::ConditionGroup.new(true_if: "any_met", negate: false, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")]) }

      it "concatenates with or" do
        expect(result).to eq "(a) or (b) or (c)"
      end
    end

    context "nested condition group" do
      let(:condition_group) { Forms::ConditionGroup.new(true_if: "any_met", negate: false, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        Forms::ConditionGroup.new(true_if: "all_met", negate: true, members: [
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c"),
           instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "d")
        ]),
        Forms::ConditionGroup.new(true_if: "all_met", negate: false, members: [
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "e"),
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "f"),
           instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "g")
        ])
      ]) }

      it "it nests groups" do
        expect(result).to eq "(a) or (not((b) and (c) and (d))) or ((e) and (f) and (g))"
      end
    end
  end
end
