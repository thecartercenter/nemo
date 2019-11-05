# frozen_string_literal: true

require "rails_helper"

describe "option_sets", type: :request do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:option_set) { create(:option_set, option_names: option_names) }
  let(:option_names) { :super_multilevel }
  let(:endpoint) { "/en/m/#{get_mission.compact_name}/condition-form-data/option-path" }

  before do
    login(user)
  end

  describe "get_condition_view" do
    context "multilevel" do
      context "nothing selected" do
        it "should return options for first level only" do
          get("#{endpoint}?option_set_id=#{option_set.id}&node_id=null")
          expected = {
            levels: [
              {name: "Kingdom",
               selected: nil,
               options: [
                 {name: "Animal", id: get_node(option_set, "Animal").id},
                 {name: "Plant", id: get_node(option_set, "Plant").id}
               ]},
              {name: "Family",
               selected: nil,
               options: []},
              {name: "Species",
               selected: nil,
               options: []}
            ]
          }.to_json
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end

      context "incomplete selection with selected ancestor" do
        it "should return options for levels that have been selected plus one level" do
          option_node = option_set.c[1].c[0]
          get("#{endpoint}?option_set_id=#{option_set.id}&node_id=#{option_node.id}")
          expected = {
            levels: [
              {name: "Kingdom",
               selected: get_node(option_set, "Plant").id,
               options: [
                 {name: "Animal", id: get_node(option_set, "Animal").id},
                 {name: "Plant", id: get_node(option_set, "Plant").id}
               ]},
              {name: "Family",
               selected: get_node(option_set, "Tree").id,
               options: [
                 {name: "Tree", id: get_node(option_set, "Tree").id},
                 {name: "Flower", id: get_node(option_set, "Flower").id}
               ]},
              {name: "Species",
               selected: nil,
               options: [
                 {name: "Oak", id: get_node(option_set, "Oak").id},
                 {name: "Pine", id: get_node(option_set, "Pine").id}
               ]}
            ]
          }.to_json
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end

      context "incomplete selection with blank options on grandchild level" do
        it "should return options for levels that have been selected plus one level but not the last" do
          option_node = option_set.c[1]
          get("#{endpoint}?option_set_id=#{option_set.id}&node_id=#{option_node.id}")
          expected = {
            levels: [
              {name: "Kingdom",
               selected: get_node(option_set, "Plant").id,
               options: [
                 {name: "Animal", id: get_node(option_set, "Animal").id},
                 {name: "Plant", id: get_node(option_set, "Plant").id}
               ]},
              {name: "Family",
               selected: nil,
               options: [
                 {name: "Tree", id: get_node(option_set, "Tree").id},
                 {name: "Flower", id: get_node(option_set, "Flower").id}
               ]},
              {name: "Species",
               selected: nil,
               options: []}
            ]
          }.to_json
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end

      context "complete selection" do
        it "should return options and selected values for all levels" do
          option_node = option_set.c[1].c[0].c[1]
          get("#{endpoint}?option_set_id=#{option_set.id}&node_id=#{option_node.id}")
          expected = {
            levels: [
              {name: "Kingdom",
               selected: get_node(option_set, "Plant").id,
               options: [
                 {name: "Animal", id: get_node(option_set, "Animal").id},
                 {name: "Plant", id: get_node(option_set, "Plant").id}
               ]},
              {name: "Family",
               selected: get_node(option_set, "Tree").id,
               options: [
                 {name: "Tree", id: get_node(option_set, "Tree").id},
                 {name: "Flower", id: get_node(option_set, "Flower").id}
               ]},
              {name: "Species",
               selected: get_node(option_set, "Pine").id,
               options: [
                 {name: "Oak", id: get_node(option_set, "Oak").id},
                 {name: "Pine", id: get_node(option_set, "Pine").id}
               ]}
            ]
          }.to_json
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end
    end

    context "select one" do
      let(:option_names) { %w[Cat Dog] }

      context "option selected" do
        it "should return json of with the selected option" do
          option_node = option_set.c[0]
          get("#{endpoint}?option_set_id=#{option_set.id}&node_id=#{option_node.id}")
          expected = {
            levels: [
              {name: nil,
               selected: get_node(option_set, "Cat").id,
               options: [
                 {name: "Cat", id: get_node(option_set, "Cat").id},
                 {name: "Dog", id: get_node(option_set, "Dog").id}
               ]}
            ]
          }.to_json
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end

      context "no option selected" do
        it "should return no selected value" do
          get("#{endpoint}?option_set_id=#{option_set.id}&node_id=null")
          expected = {
            levels: [
              {name: nil,
               selected: nil,
               options: [
                 {name: "Cat", id: get_node(option_set, "Cat").id},
                 {name: "Dog", id: get_node(option_set, "Dog").id}
               ]}
            ]
          }.to_json
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end
    end
  end

  def get_node(option_set, name)
    option_set.option_nodes.select { |n| n.option && n.option.canonical_name == name }[0]
  end
end
