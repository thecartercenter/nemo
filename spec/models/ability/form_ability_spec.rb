# Tests for abilities related to Form object.
require "rails_helper"

describe "abilities for forms" do
  context "for admin" do
    before do
      @user = create(:user, admin: true)
      @ability = Ability.new(user: @user, mode: "admin")
    end

    context "when standard" do
      before do
        @form = create(:form, question_types: %w(text), is_standard: true)
      end

      it "should have limited abilities" do
        %i(show clone update add_questions remove_questions reorder_questions destroy).each { |op| expect(@ability).to be_able_to(op, @form) }
        %i(publish).each { |op| expect(@ability).not_to be_able_to(op, @form) }
      end
    end
  end

  context "for coordinator role" do
    before do
      @user = create(:user, role_name: "coordinator")
      @ability = Ability.new(user: @user, mode: "mission", mission: get_mission)
    end

    it "should be able to create and index" do
      %i(create index).each { |op| expect(@ability).to be_able_to(op, Form) }
    end

    context "when unpublished" do
      before do
        @form = create(:form, question_types: %w(text))
      end

      it "should be able to do all except download" do
        %i(show update publish clone add_questions remove_questions reorder_questions destroy).each { |op| expect(@ability).to be_able_to(op, @form) }
        %i(download).each { |op| expect(@ability).not_to be_able_to(op, @form) }
      end

      context "with responses" do
        before do
          create(:response, form: @form, answer_values: ["foo"])
          @form.reload
        end

        it "should be able to do all but destroy" do
          %i(show update publish clone add_questions remove_questions reorder_questions).each { |op| expect(@ability).to be_able_to(op, @form) }
          %i(download destroy).each { |op| expect(@ability).not_to be_able_to(op, @form) }
        end
      end
    end

    context "when published" do
      before do
        @form = create(:form, question_types: %w(text))
        @form.publish!
      end

      it "should have limited abilities" do
        %i(show update publish download clone).each { |op| expect(@ability).to be_able_to(op, @form) }
        %i(add_questions remove_questions reorder_questions destroy).each { |op| expect(@ability).not_to be_able_to(op, @form) }
      end
    end

    context "when standard" do
      before do
        @form = create(:form, question_types: %w(text), is_standard: true)
      end

      it "should be able to do nothing" do
        %i(show update add_questions remove_questions reorder_questions destroy download publish clone).each { |op| expect(@ability).not_to be_able_to(op, @form) }
      end
    end

    context "when unpublished std copy" do
      before do
        @std = create(:form, question_types: %w(text), is_standard: true)
        @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
      end

      it "should have same abilities as unlinked unpublished form" do
        %i(show update publish clone add_questions remove_questions reorder_questions destroy).each { |op| expect(@ability).to be_able_to(op, @copy) }
        %i(download).each { |op| expect(@ability).not_to be_able_to(op, @copy) }
      end
    end
  end
end
