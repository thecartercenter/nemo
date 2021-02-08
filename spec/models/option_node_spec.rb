# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: option_nodes
#
#  id             :uuid             not null, primary key
#  ancestry       :text
#  ancestry_depth :integer          default(0), not null
#  rank           :integer          default(1), not null
#  sequence       :integer          default(0), not null
#  standard_copy  :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  mission_id     :uuid
#  old_id         :integer
#  option_id      :uuid
#  option_set_id  :uuid             not null
#  original_id    :uuid
#
# Indexes
#
#  index_option_nodes_on_ancestry       (ancestry)
#  index_option_nodes_on_mission_id     (mission_id)
#  index_option_nodes_on_option_id      (option_id)
#  index_option_nodes_on_option_set_id  (option_set_id)
#  index_option_nodes_on_original_id    (original_id)
#  index_option_nodes_on_rank           (rank)
#
# Foreign Keys
#
#  option_nodes_mission_id_fkey     (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  option_nodes_option_id_fkey      (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#  option_nodes_option_set_id_fkey  (option_set_id => option_sets.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe OptionNode do
  include OptionNodeSupport

  describe "destroy" do
    before do
      @node = create(:option_node_with_grandchildren)
      @option = @node.sorted_children[0].option
      @node.sorted_children[0].destroy
    end

    it "should not destroy option" do
      expect(Option.exists?(@option.id)).to be_truthy
    end
  end

  describe "shortcode" do
    let(:option_set) { create(:option_set, option_names: :super_multilevel) }

    it "should return shortcodes based on sequence" do
      shortcodes = option_set.descendants.map(&:shortcode).sort
      expect(shortcodes).to eq(%w[1 2 3 4 5 6 7 8 9 a b c d e])
    end
  end

  describe "max_sequence" do
    let!(:option_set) { create(:option_set, option_names: :multilevel) }

    it "should return the highest sequence in the set" do
      expect(option_set.children[0].max_sequence).to eq(6)
    end

    it "should work even when called on a leaf node" do
      expect(option_set.children[0].children[0].max_sequence).to eq(6)
    end

    context "with deleted nodes" do
      before do
        OptionNode.where(sequence: 6).destroy_all
      end

      it "should ignore the deleted node" do
        expect(option_set.children[0].max_sequence).to eq(5)
      end
    end
  end

  describe "option_level" do
    before do
      @node = create(:option_node_with_grandchildren)
      # We want to set expectations on subnode.option_set, which is nil.
      allow_message_expectations_on_nil
    end

    it "should be nil for root" do
      expect(@node.level).to be_nil
    end

    it "should be correct for first level" do
      subnode = @node.c[0]
      expect(subnode.option_set).to receive(:try).with(:level, 1).and_return(double(name: "Foo"))
      expect(subnode.level.name).to eq("Foo")
    end

    it "should be correct for second level" do
      subnode = @node.c[0].c[0]
      expect(subnode.option_set).to receive(:try).with(:level, 2).and_return(double(name: "Bar"))
      expect(subnode.level.name).to eq("Bar")
    end

    it "might be nil for first level" do
      subnode = @node.c[0]
      expect(subnode.option_set).to receive(:try).with(:level, 1).and_return(nil)
      expect(subnode.level).to be_nil
    end
  end

  describe "creating single level from hash" do
    before do
      # we use a mixture of existing and new options
      @dog = create(:option, name_en: "Dog")
      @node = OptionNode.create!(
        "option_set" => create(:option_set),
        "mission_id" => get_mission.id,
        "option" => nil,
        "children_attribs" => [
          {"option_attribs" => {"name_translations" => {"en" => "Cat"}}},
          {"option_attribs" => {"id" => @dog.id, "name_translations" => {"en" => "Dog"}}}
        ]
      )
    end

    it "should be correct" do
      expect_node(%w[Cat Dog])
    end
  end

  describe "creating multilevel from hash" do
    before do
      # we use a mixture of existing and new options
      @dog = create(:option, name_en: "Dog")
      @oak = create(:option, name_en: "Oak")
      @node = OptionNode.create!(
        "option_set" => create(:option_set),
        "option" => nil,
        "mission_id" => get_mission.id,
        "children_attribs" => [{
          "option_attribs" => {"name_translations" => {"en" => "Animal"}},
          "children_attribs" => [
            {"option_attribs" => {"name_translations" => {"en" => "Cat"}}},
            {"option_attribs" => {"id" => @dog.id}} # Existing option
          ]
        }, {
          "option_attribs" => {"name_translations" => {"en" => "Plant"}},
          "children_attribs" => [
            {"option_attribs" => {"name_translations" => {"en" => "Tulip"}}},
            # change option name
            {"option_attribs" => {"id" => @oak.id, "name_translations" => {"en" => "White Oak"}}}
          ]
        }]
      )
    end

    it "should be correct" do
      expect_node([["Animal", %w[Cat Dog]], ["Plant", ["Tulip", "White Oak"]]])
    end
  end

  describe "updating from hash with no changes" do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update!(no_change_changeset(@node))
    end

    it "should still be correct" do
      expect_node([["Animal", %w[Cat Dog]], ["Plant", %w[Tulip Oak]]])
    end

    it "should not cause ranks to change" do
      expect(@node.ranks_changed?).to eq(false)
    end

    it "should cause options_added? to be false" do
      expect(@node.options_added?).to eq(false)
    end

    it "should cause options_removed? to be false" do
      expect(@node.options_removed?).to eq(false)
    end
  end

  describe "updating from hash with full set of changes" do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update!(standard_changeset(@node))
    end

    it "should be correct" do
      expect_node([["Animal", ["Doge"]], ["Plant", %w[Cat Tulipe]]])
    end

    it "should cause ranks_changed? to become true" do
      expect(@node.ranks_changed?).to eq(true)
    end

    it "should cause options_added? to be true" do
      expect(@node.options_added?).to eq(true)
    end

    it "should cause options_removed? to be true" do
      expect(@node.options_removed?).to eq(true)
    end
  end

  describe "updating from hash, moving two options to a different node" do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update!(move_node_changeset(@node))
    end

    it "should be correct" do
      expect_node(["Animal", ["Plant", %w[Tulip Oak Cat Dog]]])
    end

    it "should cause ranks_changed? to be false" do
      expect(@node.ranks_changed?).to eq(false)
    end

    it "should cause options_added? to be true" do
      # Because moving an option is really adding and removing.
      expect(@node.options_added?).to eq(true)
    end

    it "should cause options_removed? to be true" do
      # Because moving an option is really adding and removing.
      expect(@node.options_removed?).to eq(true)
    end
  end

  describe "adding an option via hash" do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update!(additive_changeset(@node))
    end

    it "should be correct" do
      expect_node([["Animal", %w[Cat Dog Ocelot]], ["Plant", %w[Tulip Oak]]])
    end

    it "should cause ranks_changed? to be false" do
      expect(@node.ranks_changed?).to eq(false)
    end

    it "should cause options_added? to be true" do
      expect(@node.options_added?).to eq(true)
    end

    it "should cause options_removed? to be false" do
      expect(@node.options_removed?).to eq(false)
    end
  end

  describe "destroying subtree and adding new subtree" do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update!("children_attribs" => [
        no_change_changeset(@node)["children_attribs"][0],
        {
          "option_attribs" => {"name_translations" => {"en" => "Laser"}},
          "children_attribs" => [
            {
              "option_attribs" => {"name_translations" => {"en" => "Green"}}
            },
            {
              "option_attribs" => {"name_translations" => {"en" => "Red"}}
            }
          ]
        }
      ])
    end

    it "should be correct" do
      expect_node([["Animal", %w[Cat Dog]], ["Laser", %w[Green Red]]])
    end

    it "should not cause ranks_changed? to become true" do
      expect(@node.ranks_changed?).to eq(false)
    end
  end

  describe "destroying all" do
    before do
      @node = create(:option_node_with_grandchildren)

      @node.update!("children_attribs" => [])
    end

    it "should be correct" do
      expect_node([])
    end
  end

  describe "child_options" do
    it "should return child options in sorted order" do
      node = create(:option_node_with_grandchildren)
      expect(node.child_options.map(&:name)).to eq(%w[Animal Plant])
    end
  end

  describe "preferred_name_translations" do
    let(:option_node) { create(:option_node, option_attribs: {name_translations: {en: nil, fr: "Foo"}}) }

    before do
      option_node.mission.setting.update!(preferred_locales_str: "en,fr")
    end

    it "returns first non-nil translation" do
      results = option_node.preferred_name_translations([option_node.option])
      expect(results).to eq(%w[Foo])
    end
  end

  describe "#update_answer_search_vectors" do
    let!(:form) { create(:form, question_types: %w[select_one]) }
    let!(:response) { create(:response, form: form, answer_values: ["Cat"]) }
    let!(:option_node) { form.c[0].option_set.c[0] }

    context "when name translations haven't changed" do
      it "doesn't call update_answer_search_vectors" do
        expect(Results::AnswerSearchVectorUpdater.instance).not_to receive(:update_for_option_node)
        option_node.update!(option_attribs: {id: option_node.option_id,
                                             name_translations: {"en" => "Cat"}, value: 99})
      end
    end

    context "when name translations have changed" do
      it "calls update_answer_search_vectors" do
        expect(Results::AnswerSearchVectorUpdater.instance).to receive(:update_for_option_node)
        option_node.update!(option_attribs: {id: option_node.option_id,
                                             name_translations: {"en" => "Changed"}})
      end

      it "calls update_answer_search_vectors even for different language change" do
        expect(Results::AnswerSearchVectorUpdater.instance).to receive(:update_for_option_node)
        option_node.update!(option_attribs: {id: option_node.option_id,
                                             name_translations: {"en" => "Cat", "it" => "Chatto"}})
      end
    end
  end
end
