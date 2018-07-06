require "rails_helper"

describe Results::WebResponseParser do
  include_context "response tree"

  context "simple form" do
    # form item ids have to actually exist
    let(:form) { create(:form, question_types: %w[text text text]) }

    it "builds matching tree" do
      ActionController::Parameters.action_on_unpermitted_parameters = :raise

      input = ActionController::Parameters.new({
        root: {
          id: "",
          type: "AnswerGroup",
          questioning_id: form.root_group.id,
          relevant: "true",
          children: {
            "0" => {
              id: "",
              type: "Answer",
              questioning_id: form.c[0].id,
              relevant: "true",
              value: "A"
            },
            "1" => {
              id: "",
              type: "Answer",
              questioning_id: form.c[1].id,
              relevant: "true",
              value: "B"
            },
            "2" => {
              id: "",
              type: "Answer",
              questioning_id: form.c[2].id,
              relevant: "true",
              value: "C"
            }
          }
        }
      })
      tree = Results::WebResponseParser.new.parse(input)
      puts tree.debug_tree
      expect(tree.questioning_id).to eq form.root_group.id
      expect_children(tree, %w[Answer Answer Answer], form.c.map(&:id), %w[A B C])
    end

    context "forms with a group" do
      let(:form) { create(:form, question_types: ["text", %w[text text], "text"]) }

      xit "should produce the correct tree" do
        input = {
          root: {
            id: "",
            type: "AnswerGroup",
            questioning_id: form.root_group.id,
            relevant: "true",
            children: {
              "0" => {
                id: "",
                type: "Answer",
                questioning_id: form.c[0].id,
                relevant: "true",
                value: "A"
              },
              "1" => {
                id: "",
                type: "AnswerGroup",
                questioning_id: form.c[1].id,
                relevant: "true",
                children:  {
                  "0" => {
                    id: "",
                    type: "Answer",
                    questioning_id: form.c[0].id,
                    relevant: "true",
                    value: "B"
                  },
                  "1" => {
                    id: "",
                    type: "Answer",
                    questioning_id: form.c[1].id,
                    relevant: "true",
                    children: "C"
                  }
                }
              },
              "2" => {
                id: "",
                type: "Answer",
                questioning_id: form.c[2].id,
                relevant: "true",
                value: "D"
              }
            }
          }
        }
        expect_root(response_tree, form)
        expect_children(response_tree, %w[Answer AnswerGroup Answer], form.c.map(&:id))
        expect_children(response_tree.c[1], %w[Answer Answer], form.c[1].c.map(&:id))
      end
    end

  end
end
