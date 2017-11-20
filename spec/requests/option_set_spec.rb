require "spec_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe "option_sets", type: :request do
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  describe "get_condition_view" do
    context "multilevel" do

      let(:option_set) { create(:option_set, super_multilevel: true) }

      it "should return json of condition view of option set" do
        option_node = option_set.option_nodes.select {|n| n.option && n.option.canonical_name == "Tree"}[0]
        get "/en/m/#{get_mission.compact_name}/option-sets/#{option_set.id}/condition-form-view?node_id=#{option_node.id}"
        expected = {
          levels: [
            {name: "Kingdom",
             selected: get_node(option_set, "Plant").option.id,
             options: [
               {name: "Animal", id: get_node(option_set, "Animal").option.id},
               {name: "Plant", id: get_node(option_set, "Plant").option.id}
              ]
            },
            {name: "Family",
             selected: get_node(option_set, "Tree").option.id,
             options: [
               {name: "Tree", id: get_node(option_set, "Tree").option.id},
               {name: "Flower", id: get_node(option_set, "Flower").option.id}
              ]
            },
            {name: "Species",
             selected: nil,
             options: [
               {name: "Oak", id: get_node(option_set, "Oak").option.id},
               {name: "Pine", id: get_node(option_set, "Pine").option.id}
              ]
            }
          ]
        }.to_json

        expect(response).to have_http_status(200)
        expect(response.body).to eq expected
      end
    end

    context "select one" do
      let(:option_set) { create(:option_set) }

      it "should return json of condition view of option set" do
        option_node = option_set.option_nodes.select {|n| n.option && n.option.canonical_name == "Cat"}[0]
        get "/en/m/#{get_mission.compact_name}/option-sets/#{option_set.id}/condition-form-view?node_id=#{option_node.id}"
        expected = {
          levels: [
            {name: nil,
             selected: get_node(option_set, "Cat").option.id,
             options: [
               {name: "Cat", id: get_node(option_set, "Cat").option.id},
               {name: "Dog", id: get_node(option_set, "Dog").option.id}
              ]
            }
          ]
        }.to_json

        expect(response).to have_http_status(200)
        expect(response.body).to eq expected
      end
    end
  end

  def get_node(option_set, name)
    option_set.option_nodes.select {|n| n.option && n.option.canonical_name == name}[0]
  end
end
