require "spec_helper"

module Odk
  describe ConditionGroupDecorator, :odk, :reset_factory_sequences, database_cleaner: :truncate do
    context "non-nested condition group all true" do

      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [double(to_odk: "foo"), double(to_odk: "bar"), double(to_odk: "baz")]) }
      it "" do
        expect(result).to eq "(foo) and (bar) and (baz)"
      end
    end

    context "non-nested condition group negated" do

      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: true, members: [double(to_odk: "foo"), double(to_odk: "bar"), double(to_odk: "baz")]) }

      it "" do
        expect(result).to eq "not((foo) and (bar) and (baz))"
      end
    end

    context "nested condition group" do

      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [

        #decorated? replace w/ draper property that says it's already decorated
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "foo"),
        Forms::ConditionGroup.new( true_if: "all_met", negate: true, members: [double(to_odk: "foo"), double(to_odk: "bar"), double(to_odk: "baz")]),
        Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [double(to_odk: "foo"), double(to_odk: "bar"), double(to_odk: "baz")])
      ]) }

      it "" do
      end
    end

    def decorate(obj)
      Odk::DecoratorFactory.decorate(obj)
    end
  end
end
