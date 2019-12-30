# frozen_string_literal: true

require "rails_helper"

describe Response do
  include_context "response tree"

  let(:form) { create(:form, question_types: [%w[integer], "text"]) }
  let(:response) { create(:response, form: form, answer_values: nil) }
  let(:root_node) { response.root_node }
  let(:group) { root_node.c[0] }

  before do
    response.build_root_node(type: "AnswerGroup", form_item: form.root_group, new_rank: 0)
    root_node.children.build(type: "AnswerGroup", form_item: form.c[0], new_rank: 0)
    root_node.c[0].children.build(type: "Answer", form_item: form.c[0].c[0], new_rank: 0, value: int_answer)
    root_node.children.build(type: "Answer", form_item: form.c[1], new_rank: 1, value: "A")
  end

  context "tree is valid" do
    let(:int_answer) { 1 }
    it "builds a correct tree" do
      expect_root(root_node, form)
      expect_built_children(root_node, %w[AnswerGroup Answer], form.c.map(&:id), [nil, "A"])
      expect_built_children(group, %w[Answer], [form.c[0].c[0].id], [1])
    end

    it "saves the correct tree" do
      response.save!
      saved_response = Response.find(response.id) # ensure all data is fresh from db
      expect_root(saved_response.root_node, form)
      expect_children(saved_response.root_node, %w[AnswerGroup Answer], form.c.map(&:id), [nil, "A"])
      expect_children(saved_response.root_node.c[0], %w[Answer], [form.c[0].c[0].id], [1])
    end

    it "updates an updated node when response is saved" do
      response.save!
      saved_response = Response.find(response.id) # ensure all data is fresh from db
      expect_root(saved_response.root_node, form)
      expect_children(saved_response.root_node, %w[AnswerGroup Answer], form.c.map(&:id), [nil, "A"])
      expect_children(saved_response.root_node.c[0], %w[Answer], [form.c[0].c[0].id], [1])
      node_to_update = saved_response.root_node.c[0].c[0]
      node_to_update.value = 3
      saved_response.save!
      saved_response = Response.find(response.id) # ensure all data is fresh from db
      expect_root(saved_response.root_node, form)
      expect_children(saved_response.root_node, %w[AnswerGroup Answer], form.c.map(&:id), [nil, "A"])
      expect_children(saved_response.root_node.c[0], %w[Answer], [form.c[0].c[0].id], [3])
    end

    context "nested form" do
      let(:nested_question_types) { ["text", {repeating: {items: ["text", {repeating: {items: ["text"]}}]}}] }
      let(:nested_form) { create(:form, question_types: nested_question_types) }
      let(:nested_response) { build(:response, form: nested_form, answer_values: nested_answer_values) }
      let(:nested_answer_values) do
        [
          "A",
          {repeating: [
            [ # to be marked destroy
              "B",
              {repeating: [["C"], ["D"]]}
            ],
            [
              "E", # to be marked irrelevant
              {repeating: [["F"], ["G"]]}
            ]
          ]}
        ]
      end

      it "removes irrelevant nodes and nodes marked destroy before save" do
        node_to_destroy = nested_response.root_node.c[1].c[0]
        node_to_destroy._destroy = true
        expect(node_to_destroy.type).to eq("AnswerGroup")
        expect(node_to_destroy._destroy).to be(true)

        irrelevant_node = nested_response.root_node.c[1].c[1].c[0]
        irrelevant_node.relevant = false
        expect(irrelevant_node.value).to eq("E")
        expect(irrelevant_node.relevant).to be(false)

        nested_response.save!
        saved_response = Response.find(nested_response.id)

        expect_children( # check destroyed node removed
          saved_response.root_node.c[1],
          ["AnswerGroup"],
          [nested_form.root_group.c[1].id]
        )

        expect_children( # check irrelevant node removed
          saved_response.root_node.c[1].c[0],
          ["AnswerGroupSet"],
          [nested_form.root_group.c[1].c[1].id]
        )
      end
    end
  end

  context "tree includes invalid node" do
    let(:int_answer) { "invalid" }
    it "errors with validation error on invalid node" do
      expect { response.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(group.c[0].errors[:value].join).to match("Please enter a valid number")
    end
  end
end
