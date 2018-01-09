require "spec_helper"

module Odk
  describe ConditionGroupDecorator, :odk, :reset_factory_sequences, database_cleaner: :truncate do

    context "empty condition group" do
      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [])}

      it "should return nil" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to be_nil
      end
    end

    context "non-nested condition group all true" do
      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")
      ]) }

      it "concatenates with and" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to eq "(a) and (b) and (c)"
      end
    end

    context "non-nested condition group negated" do
      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: true, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")
      ])}

      it "adds the xpath not function" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to eq "not((a) and (b) and (c))"
      end
    end

    context "non-nested condition group with any true" do
      let(:condition_group) { Forms::ConditionGroup.new( true_if: "any_met", negate: false, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")]) }

      it "concatenates with or" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to eq "(a) or (b) or (c)"
      end
    end

    context "nested condition group" do
      let(:condition_group) { Forms::ConditionGroup.new( true_if: "any_met", negate: false, members: [
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        Forms::ConditionGroup.new( true_if: "all_met", negate: true, members: [
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"),
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c"),
           instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "d")
        ]),
        Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "e"),
          instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "f"),
           instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "g")
        ])
      ]) }

      it "it nests groups" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to eq "(a) or (not((b) and (c) and (d))) or ((e) and (f) and (g))"
      end
    end
  end
end
