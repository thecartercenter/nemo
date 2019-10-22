# frozen_string_literal: true

# Tests for abilities related to Question object.
require "rails_helper"

describe "abilities for questions" do
  context "for coordinator role" do
    let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }
    let(:user) { create(:user, role_name: "coordinator") }

    it "should be able to create and index" do
      %i[create index].each { |op| expect(ability).to be_able_to(op, Question) }
    end

    context "when draft" do
      let(:form) { create(:form, question_types: %w[text]) }
      let(:question) { form.questions.first }

      it "should be able to do all" do
        %i[show update update_code update_core destroy].each do |op|
          expect(ability).to be_able_to(op, question)
        end
      end

      context "with answers" do
        before do
          create(:response, form: form, answer_values: ["foo"])
        end

        it "should be able to do all but destroy and update core" do
          %i[show update update_code].each { |op| expect(ability).to be_able_to(op, question) }
          %i[update_core destroy].each { |op| expect(ability).not_to be_able_to(op, question) }
        end
      end
    end

    context "when live" do
      let(:form) { create(:form, :live, question_types: %w[text]) }
      let(:question) { form.questions.first }

      it "should be able show and update only" do
        %i[show update update_code].each { |op| expect(ability).to be_able_to(op, question) }
        %i[update_core destroy].each { |op| expect(ability).not_to be_able_to(op, question) }
      end
    end

    context "when std copy" do
      let(:std) { create(:form, :standard, question_types: %w[text]) }
      let(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let(:question) { copy.questions.first }

      it "should be able to do all except update_code" do
        %i[show update update_core destroy].each { |op| expect(ability).to be_able_to(op, question) }
        %i[update_code].each { |op| expect(ability).not_to be_able_to(op, question) }
      end
    end
  end
end
