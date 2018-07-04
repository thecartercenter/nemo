require "rails_helper"

describe OptionNodePath do
  include OptionNodeSupport

  let(:sl_set) { create(:option_set) }
  let(:ml_set) { create(:option_set, multilevel: true) }
  let(:sml_set) { create(:option_set, super_multilevel: true) }
  let(:node) { sl_set.sorted_children[1] } # Dog
  let(:leaf_node) { ml_set.sorted_children[0].sorted_children[1] } # Dog
  let(:interior_node) { sml_set.sorted_children[1] } # Plant

  describe "blank?" do
    it "should be true for nil target_node" do
      expect(OptionNodePath.new(option_set: sl_set, target_node: nil).blank?).to be true
    end

    it "should be false for non-nil target_node" do
      expect(OptionNodePath.new(option_set: sl_set, target_node: node).blank?).to be false
    end
  end

  describe "nodes_for_depth" do
    context "single level set" do
      let(:path) { OptionNodePath.new(option_set: sl_set, target_node: node) }

      it "should be correct for valid levels" do
        expect(path.nodes_for_depth(1).map(&:option_name)).to eq %w(Cat Dog)
      end
    end

    context "multilevel set with leaf target node" do
      let(:path) { OptionNodePath.new(option_set: ml_set, target_node: leaf_node) }

      it "should raise error for depth 0" do
        expect{ path.nodes_for_depth(0) }.to raise_error(ArgumentError)
      end

      it "should be correct for valid levels" do
        expect(path.nodes_for_depth(1).map(&:option_name)).to eq %w(Animal Plant)
        expect(path.nodes_for_depth(2).map(&:option_name)).to eq %w(Cat Dog)
      end
    end

    context "mutlilevel set with interior target node" do
      let(:path) { OptionNodePath.new(option_set: sml_set, target_node: interior_node) }

      it "should be correct for valid level" do
        expect(path.nodes_for_depth(1).map(&:option_name)).to eq %w(Animal Plant)
        expect(path.nodes_for_depth(2).map(&:option_name)).to eq %w(Tree Flower)
      end

      it "should be empty for unspecified level" do
        expect(path.nodes_for_depth(3)).to eq []
      end
    end

    context "with nil target_node" do
      let(:path) { OptionNodePath.new(option_set: ml_set, target_node: nil) }

      it "should be correct" do
        expect(path.nodes_for_depth(1).map(&:option_name)).to eq %w(Animal Plant)
        expect(path.nodes_for_depth(2)).to eq []
      end
    end
  end
end
