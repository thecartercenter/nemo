require "rails_helper"

describe Results::WebResponseParser do
  include_context "response tree"

  context "simple response with three answers" do
    # form item ids have to actually exist
    let(:form) { create(:form, question_types: %w[text text text]) }
    let(:data) do
      {
        root: {
          id: "",
          type: "AnswerGroup",
          questioning_id: form.root_group.id,
          relevant: "true",
          children: answers
        }
      }
    end

    context "all relevant, none destroyed" do
      let(:answers) do
        {
          "0" => web_answer_hash(form.c[0].id, "A"),
          "1" => web_answer_hash(form.c[1].id, "B"),
          "2" => web_answer_hash(form.c[2].id, "C")
        }
      end

      it "builds tree with three answers" do
        input = ActionController::Parameters.new(data)
        tree = Results::WebResponseParser.new.parse(input)
        expect_root(tree, form)
        expect_children(tree, %w[Answer Answer Answer], form.c.map(&:id), %w[A B C])
      end
    end

    context "with one irrelevant answer" do
      let(:answers) do
        {
          "0" => web_answer_hash(form.c[0].id, "A"),
          "1" => web_answer_hash(form.c[1].id, "B", relevant: false),
          "2" => web_answer_hash(form.c[2].id, "C")
        }
      end

      it "builds tree with two answers" do
        input = ActionController::Parameters.new(data)
        tree = Results::WebResponseParser.new.parse(input)
        expect_root(tree, form)
        expect_children(tree, %w[Answer Answer], [form.c[0].id, form.c[2].id], %w[A C])
      end
    end

    context "with one destroyed answer" do
      let(:answers) do
        {
          "0" => web_answer_hash(form.c[0].id, "A"),
          "1" => web_answer_hash(form.c[1].id, "B", destroy: true),
          "2" => web_answer_hash(form.c[2].id, "C")
        }
      end

      it "builds tree with two answers" do
        input = ActionController::Parameters.new(data)
        tree = Results::WebResponseParser.new.parse(input)
        expect_root(tree, form)
        expect_children(tree, %w[Answer Answer], [form.c[0].id, form.c[2].id], %w[A C])
      end
    end
  end

  context "response with a group" do
    let(:form) { create(:form, question_types: ["text", %w[text text], "text"]) }

    it "should produce the correct tree" do
      input = ActionController::Parameters.new(
        root: {
          id: "",
          type: "AnswerGroup",
          questioning_id: form.root_group.id,
          relevant: "true",
          children: {
            "0" => web_answer_hash(form.c[0].id, "A"),
            "1" => {
              id: "",
              type: "AnswerGroup",
              questioning_id: form.c[1].id,
              relevant: "true",
              children:  {
                "0" => web_answer_hash(form.c[1].c[0].id, "B"),
                "1" => web_answer_hash(form.c[1].c[1].id, "C")
              }
            },
            "2" => web_answer_hash(form.c[2].id, "D")
          }
        }
      )
      tree = Results::WebResponseParser.new.parse(input)
      expect_root(tree, form)
      expect_children(tree, %w[Answer AnswerGroup Answer], form.c.map(&:id), ["A", nil, "D"])
      expect_children(tree.c[1], %w[Answer Answer], form.c[1].c.map(&:id), %w[B C])
    end
  end

  context "response with an answer set" do
    it "builds tree with answer set" do
    end
  end

  context "response with an answer group set" do
    it "builds tree with answer group set" do
    end
  end
end
