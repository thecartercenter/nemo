# frozen_string_literal: true

require "rails_helper"

describe "abilities for option nodes" do
  include_context "ability"

  let(:object) { option_node }
  let(:option_node) { create(:option_node_with_children) }
  let(:all) { Ability::CRUD }

  context "mission mode" do
    let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }

    context "for coordinator" do
      let(:user) { create(:user, role_name: "coordinator") }

      it "should be able to create and index" do
        %i[create index].each { |op| expect(ability).to be_able_to(op, OptionNode) }
      end

      context "with a form" do
        let(:form) { create(:form, question_types: %w[select_one]) }
        let(:option_node) { form.questions[0].option_set.children[0] }

        context "without data" do
          let(:permitted) { all }
          it_behaves_like "has specified abilities"
        end

        context "with data" do
          let!(:response) { create(:response, form: form, answer_values: [option_node.name]) }
          let(:permitted) { all - %i[destroy] }

          it_behaves_like "has specified abilities"

          context "if deleted" do
            let(:permitted) { all }

            before do
              response.destroy
              option_node.reload
            end

            it_behaves_like "has specified abilities"
          end
        end

        context "with condition" do
          let(:form) { create(:form, question_types: %w[select_one text]) }
          let!(:condition) do
            create(:condition, conditionable: form.c[1], left_qing: form.c[0], option_node: option_node)
          end
          let(:permitted) { all - %i[destroy] }

          it_behaves_like "has specified abilities"
        end
      end
    end

    shared_examples_for "enumerator abilities" do
      it "shouldn't be able to create" do
        expect(ability).not_to be_able_to(:create, OptionNode)
      end

      it "should be able to get child nodes for multilevel" do
        expect(ability).to be_able_to(:child_nodes, OptionNode)
      end

      context "for instance" do
        let(:permitted) { [:show] }
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
