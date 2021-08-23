# frozen_string_literal: true

require "rails_helper"

describe "abilities for forms" do
  include_context "ability"

  let(:object) { form }
  let(:all) do
    Ability::CRUD + %i[add_questions change_status clone download remove_questions reorder_questions]
  end

  context "admin mode" do
    let(:user) { create(:user, admin: true) }
    let(:ability) { Ability.new(user: user, mode: "admin") }

    context "when standard" do
      let(:form) { create(:form, :standard, question_types: %w[text]) }
      let(:permitted) { all - %i[download change_status] }
      it_behaves_like "has specified abilities"
    end
  end

  context "mission mode" do
    let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }

    context "for admin" do
      let(:user) { create(:user, admin: true) }

      it "should allow re-caching forms" do
        expect(ability).to be_able_to(:re_cache, Form)
      end

      it "should allow viewing raw odata link" do
        expect(ability).to be_able_to(:view_raw_odata, Form)
      end
    end

    context "for coordinator" do
      let(:user) { create(:user, role_name: "coordinator") }

      it "should be able to create and index" do
        %i[create index].each { |op| expect(ability).to be_able_to(op, Form) }
      end

      it "should not be able to re-cache" do
        %i[re_cache].each { |op| expect(ability).not_to be_able_to(op, Form) }
      end

      it "should not be able to view raw odata link" do
        %i[view_raw_odata].each { |op| expect(ability).not_to be_able_to(op, Form) }
      end

      context "when draft" do
        let(:form) { create(:form, question_types: %w[text]) }

        context "without responses" do
          let(:permitted) { all - %i[download] }
          it_behaves_like "has specified abilities"
        end

        context "with responses" do
          let(:permitted) { all - %i[download destroy] }

          before do
            create(:response, form: form, answer_values: ["foo"])
            form.reload
          end

          it_behaves_like "has specified abilities"
        end
      end

      context "when live" do
        let(:form) { create(:form, :live, question_types: %w[text]) }
        let(:permitted) { all - %i[add_questions remove_questions reorder_questions destroy] }
        it_behaves_like "has specified abilities"
      end

      context "when standard" do
        let(:form) { create(:form, :standard, question_types: %w[text]) }
        let(:permitted) { [] }
        it_behaves_like "has specified abilities"
      end

      context "when unpublished std copy" do
        let(:std) { create(:form, :standard, question_types: %w[text]) }
        let(:form) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
        let(:permitted) { all - %i[download] }
        it_behaves_like "has specified abilities"
      end
    end

    shared_examples_for "enumerator abilities" do
      it "should be able to index but not create" do
        expect(ability).to be_able_to(:index, Form)
        expect(ability).not_to be_able_to(:create, Form)
        expect(ability).not_to be_able_to(:re_cache, Form)
        expect(ability).not_to be_able_to(:view_raw_odata, Form)
      end

      context "when draft" do
        let(:form) { create(:form, question_types: %w[text]) }
        let(:permitted) { [] }
        it_behaves_like "has specified abilities"
      end

      context "when paused" do
        let(:form) { create(:form, :paused, question_types: %w[text]) }
        let(:permitted) { [] }
        it_behaves_like "has specified abilities"
      end

      context "when live" do
        let(:form) { create(:form, :live, question_types: %w[text]) }
        let(:permitted) { %i[index show download] }
        it_behaves_like "has specified abilities"
      end
    end

    context "for staffer" do
      let(:user) { create(:user, role_name: "staffer") }
      it_behaves_like "enumerator abilities"
    end

    context "for reviewer" do
      let(:user) { create(:user, role_name: "reviewer") }
      it_behaves_like "enumerator abilities"
    end

    context "for enumerator" do
      let(:user) { create(:user, role_name: "enumerator") }
      it_behaves_like "enumerator abilities"
    end
  end
end
