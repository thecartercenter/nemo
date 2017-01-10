require "spec_helper"

describe OptionNodePath do
  include OptionNodeSupport

  let(:sl_set) { create(:option_set) }
  let(:ml_set) { create(:option_set, multilevel: true) }
  let(:sml_set) { create(:option_set, super_multilevel: true) }
  let(:node) { sl_set.children[1] } # Dog
  let(:leaf_node) { ml_set.children[0].children[1] } # Dog
  let(:interior_node) { sml_set.children[1] } # Plant

  describe "options_for_depth" do
    context "single level set" do
      let(:path) { OptionNodePath.new(target_node: node) }

      it "should be correct for valid levels" do
        expect(path.options_for_depth(1).map(&:name)).to eq %w(Cat Dog)
      end
    end

    context "multilevel set with leaf target node" do
      let(:path) { OptionNodePath.new(target_node: leaf_node) }

      it "should raise error for depth 0" do
        expect{ path.options_for_depth(0) }.to raise_error(ArgumentError)
      end

      it "should be correct for valid levels" do
        expect(path.options_for_depth(1).map(&:name)).to eq %w(Animal Plant)
        expect(path.options_for_depth(2).map(&:name)).to eq %w(Cat Dog)
      end
    end

    context "mutlilevel set with interior target node" do
      let(:path) { OptionNodePath.new(target_node: interior_node) }

      it "should be correct for valid level" do
        expect(path.options_for_depth(1).map(&:name)).to eq %w(Animal Plant)
        expect(path.options_for_depth(2).map(&:name)).to eq %w(Tree Flower)
      end

      it "should be empty for unspecified level" do
        expect(path.options_for_depth(3)).to eq []
      end
    end
  end

  describe "option_ids_with_no_nils" do
    let(:path) { OptionNodePath.new(target_node: leaf_node) }

    it "should be correct" do
      expect(path.option_ids_with_no_nils).to eq [
        ml_set.children[0].option_id,
        ml_set.children[0].children[1].option_id
      ]
    end
  end
end
