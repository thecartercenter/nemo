# frozen_string_literal: true

require "rails_helper"

describe "abilities for qing groups" do
  include_context "ability"

  let(:object) { qing_group }
  let(:qing_group) { create(:qing_group, form: form) }
  let(:all) { Ability::CRUD }

  context "admin mode" do
    let(:user) { create(:user, admin: true) }
    let(:ability) { Ability.new(user: user, mode: "admin") }

    context "when standard" do
      let(:form) { create(:form, :standard, question_types: %w[text]) }
      let(:permitted) { all }
      it_behaves_like "has specified abilities"
    end
  end

  context "mission mode" do
    let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }

    context "for coordinator" do
      let(:user) { create(:user, role_name: "coordinator") }

      it "should be able to create and index" do
        %i[create index].each { |op| expect(ability).to be_able_to(op, QingGroup) }
      end

      context "when draft" do
        let(:form) { create(:form, question_types: %w[text]) }

        context "without responses" do
          let(:permitted) { all }
          it_behaves_like "has specified abilities"
        end

        context "with responses" do
          let(:permitted) { all }

          before do
            create(:response, form: form, answer_values: ["foo"])
            form.reload
          end

          it_behaves_like "has specified abilities"
        end
      end

      context "when live" do
        let(:form) { create(:form, :live, question_types: %w[text]) }
        let(:permitted) { all }
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
        let(:permitted) { all }
        it_behaves_like "has specified abilities"
      end
    end

    shared_examples_for "enumerator abilities" do
      it "shouldn't be able to index or create" do
        expect(ability).not_to be_able_to(:index, QingGroup)
        expect(ability).not_to be_able_to(:create, QingGroup)
      end

      context "when draft" do
        let(:form) { create(:form, question_types: %w[text]) }
        let(:permitted) { [] }
        it_behaves_like "has specified abilities"
      end

      context "when live" do
        let(:form) { create(:form, :live, question_types: %w[text]) }
        let(:permitted) { [] }
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
