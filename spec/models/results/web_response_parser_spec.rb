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
          "0" => web_answer_hash(form.c[0].id, value: "A"),
          "1" => web_answer_hash(form.c[1].id, value: "B"),
          "2" => web_answer_hash(form.c[2].id, value: "C")
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
          "0" => web_answer_hash(form.c[0].id, value: "A"),
          "1" => web_answer_hash(form.c[1].id, {value: "B"}, relevant: "false"),
          "2" => web_answer_hash(form.c[2].id, value: "C")
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
          "0" => web_answer_hash(form.c[0].id, value: "A"),
          "1" => web_answer_hash(form.c[1].id, {value: "B"}, destroy: "true"),
          "2" => web_answer_hash(form.c[2].id, value: "C")
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

  context "response with an answer set" do
    let(:form) { create(:form, question_types: %w[text multilevel_select_one text]) }
    let(:input) do
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
    let(:plant) { form.c[1].option_set.sorted_children[1].id }
    let(:oak) { form.c[1].option_set.sorted_children[1].sorted_children[1].id }
    let(:answers) do
      {
        "0" => web_answer_hash(form.c[0].id, value: "A"),
        "1" => {
          id: "",
          type: "AnswerSet",
          questioning_id: form.c[1].id,
          relevant: "true",
          children: {
            "0" => web_answer_hash(form.c[1].id, option_node_id: plant),
            "1" => web_answer_hash(form.c[1].id, option_node_id: oak)
          }
        },
        "2" => web_answer_hash(form.c[2].id, value: "D")
      }
    end

    it "builds tree with answer set" do
      tree = Results::WebResponseParser.new.parse(ActionController::Parameters.new(input))
      expect_root(tree, form)
      expect_children(tree, %w[Answer AnswerSet Answer], form.c.map(&:id), ["A", nil, "D"])
      expect_children(tree.c[1], %w[Answer Answer], [form.c[1].id, form.c[1].id], %w[Plant Oak])
    end
  end

  context "builds tree for response with select multiple answer" do
    let(:form) { create(:form, question_types: %w[text select_multiple text]) }
    let(:input) do
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
    let(:dog) { form.c[1].option_set.sorted_children[0].id }
    let(:cat) { form.c[1].option_set.sorted_children[1].id }
    let(:answers) do
      {
        "0" => web_answer_hash(form.c[0].id, value: "A"),
        "1" => web_answer_hash(form.c[1].id,
          choices_attributes: {
            "0" => {option_node_id: dog, checked: "1"},
            "1" => {option_node_id: cat, checked: "1"}
          }),
        "2" => web_answer_hash(form.c[2].id, value: "D")
      }
    end

    it "builds tree with answer set" do
      tree = Results::WebResponseParser.new.parse(ActionController::Parameters.new(input))
      expect_root(tree, form)
      expect_children(tree, %w[Answer Answer Answer], form.c.map(&:id), ["A", "Cat;Dog", "D"])
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
            "0" => web_answer_hash(form.c[0].id, value: "A"),
            "1" => {
              id: "",
              type: "AnswerGroup",
              questioning_id: form.c[1].id,
              relevant: "true",
              children:  {
                "0" => web_answer_hash(form.c[1].c[0].id, value: "B"),
                "1" => web_answer_hash(form.c[1].c[1].id, value: "C")
              }
            },
            "2" => web_answer_hash(form.c[2].id, value: "D")
          }
        }
      )
      tree = Results::WebResponseParser.new.parse(input)
      expect_root(tree, form)
      expect_children(tree, %w[Answer AnswerGroup Answer], form.c.map(&:id), ["A", nil, "D"])
      expect_children(tree.c[1], %w[Answer Answer], form.c[1].c.map(&:id), %w[B C])
    end
  end

  context "response with an answer group set" do
    let(:form) { create(:form, question_types: ["text", {repeating: {items: %w[text text]}}]) }
    let(:input) do
      ActionController::Parameters.new(
        root: {
          id: "",
          type: "AnswerGroup",
          questioning_id: form.root_group.id,
          relevant: "true",
          children: {
            "0" => web_answer_hash(form.c[0].id, value: "A"),
            "1" => {
              id: "",
              type: "AnswerGroupSet",
              questioning_id: form.c[1].id,
              relevant: "true",
              children: answer_groups
            }
          }
        }
      )
    end
    let(:answer_groups) do
      {
        "0" => {
          id: "",
          type: "AnswerGroup",
          questioning_id: form.c[1].id,
          relevant: "true",
          children: answers1
        },
        "1" => {
          id: "",
          type: "AnswerGroup",
          questioning_id: form.c[1].id,
          relevant: "true",
          children: answers2
        }
      }
    end
    let(:answers1) do
      {
        "0" => web_answer_hash(form.c[1].c[0].id, value: "B"),
        "1" => web_answer_hash(form.c[1].c[1].id, value: "C")
      }
    end
    let(:answers2) do
      {
        "0" => web_answer_hash(form.c[1].c[0].id, value: "D"),
        "1" => web_answer_hash(form.c[1].c[1].id, value: "E")
      }
    end

    it "builds tree with answer group set" do
      tree = Results::WebResponseParser.new.parse(input)
      expect_root(tree, form)
      expect_children(tree, %w[Answer AnswerGroupSet], form.c.map(&:id), ["A", nil])
      expect_children(tree.c[1], %w[AnswerGroup AnswerGroup], [form.c[1].id, form.c[1].id])
      expect_children(tree.c[1].c[0], %w[Answer Answer], form.c[1].c.map(&:id), %w[B C])
      expect_children(tree.c[1].c[1], %w[Answer Answer], form.c[1].c.map(&:id), %w[D E])
    end
  end
end
