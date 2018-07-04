# Tests for abilities related to Question object.
require "rails_helper"

describe "abilities for questions" do
  context "for coordinator role" do
    before do
      @user = create(:user, role_name: "coordinator")
      @ability = Ability.new(user: @user, mode: "mission", mission: get_mission)
    end

    it "should be able to create and index" do
      %i(create index).each { |op| expect(@ability).to be_able_to(op, Question) }
    end

    context "when unpublished" do
      before do
        @form = create(:form, question_types: %w(text))
        @question = @form.questions.first
      end

      it "should be able to do all" do
        %i(show update update_code update_core destroy).each { |op| expect(@ability).to be_able_to(op, @question) }
      end

      context "with answers" do
        before do
          create(:response, form: @form, answer_values: ["foo"])
        end

        it "should be able to do all but destroy and update core" do
          %i(show update update_code).each { |op| expect(@ability).to be_able_to(op, @question) }
          %i(update_core destroy).each { |op| expect(@ability).not_to be_able_to(op, @question) }
        end
      end
    end

    context "when published" do
      before do
        @form = create(:form, question_types: %w(text))
        @form.publish!
        @question = @form.questions.first
      end

      it "should be able show and update only" do
        %i(show update update_code).each { |op| expect(@ability).to be_able_to(op, @question) }
        %i(update_core destroy).each { |op| expect(@ability).not_to be_able_to(op, @question) }
      end
    end

    context "when unpublished std copy" do
      before do
        @std = create(:form, question_types: %w(text), is_standard: true)
        @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
        @question = @copy.questions.first
      end

      it "should be able to do all except update_code" do
        %i(show update update_core destroy).each { |op| expect(@ability).to be_able_to(op, @question) }
        %i(update_code).each { |op| expect(@ability).not_to be_able_to(op, @question) }
      end
    end
  end
end
