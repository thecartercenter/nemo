require "rails_helper"

describe OptionSet do
  include OptionNodeSupport

  it "should get constructed properly" do
    os = create(:option_set, multilevel: true)
    # This assertion checks that option_set, mission, and is_standard? get cascaded properly.
    expect_node([["Animal", ["Cat", "Dog"]], ["Plant", ["Tulip", "Oak"]]], os.root_node)
    expect(Option.count).to eq 6
    expect(OptionNode.count).to eq 7
  end

  it "should get constructed properly if standard" do
    os = create(:option_set, is_standard: true)
    expect_node(["Cat", "Dog"], os.root_node)
  end

  it "should get updated properly" do
    os = create(:option_set)
    os.update_attributes!(children_attribs: OptionNodeSupport::WITH_GRANDCHILDREN_ATTRIBS)
    expect_node([["Animal", ["Cat", "Dog"]], ["Plant", ["Tulip", "Oak"]]], os.reload.root_node)
  end

  it "should delegate ranks_changed? to root node" do
    os = create(:option_set)
    expect(os.root_node).to receive(:ranks_changed?)
    os.ranks_changed?
  end

  it "should delegate multilevel? to root node" do
    os = create(:option_set)
    expect(os.root_node).to receive(:has_grandchildren?)
    os.multilevel?
  end

  it "should be destructible" do
    os = create(:option_set)
    os.destroy
    expect(OptionSet.exists?(os.id)).to be false
    expect(OptionNode.where(option_set_id: os.id).count).to eq 0
  end

  describe "options" do
    before { @set = create(:option_set, multilevel: true) }

    it "should delegate to option node child options" do
      expect(@set.root_node).to receive(:child_options)
      @set.options
    end
  end

  describe "core_changed?" do
    before { @set = create(:option_set) }

    it "should return true if name changed" do
      @set.name = "Foobar"
      expect(@set.core_changed?).to eq true
    end

    it "should return false if name didnt change" do
      expect(@set.core_changed?).to eq false
    end
  end

  describe "levels" do
    it "should be nil for single level set" do
      set = create(:option_set)
      expect(set.levels).to be_nil
    end

    it "should be correct for multi level set" do
      set = create(:option_set, multilevel: true)
      expect(set.levels[0].name).to eq "Kingdom"
      expect(set.levels[1].name).to eq "Species"
    end
  end

  describe "worksheet_name" do
    it "should return the original name if valid" do
      set = create(:option_set)
      expect(set.worksheet_name).to eq set.name
    end

    it "should return a replaced name if invalid" do
      set = create(:option_set, name: 'My Options?: ~*[Yes/No:No\Yes]*~')
      expect(set.worksheet_name.size).to be <= 31
      expect(set.worksheet_name).to eq "My Options- ~∗(Yes-No-No-Ye..."
    end
  end

  describe "fetch_by_shortcode" do
    let!(:option_set) { create(:option_set, super_multilevel: true) }
    let!(:option_node) { option_set.preordered_option_nodes.last }

    it "should fetch the correct node from shortcode" do
      fetched_node = option_set.fetch_by_shortcode("e")
      expect(fetched_node.id).to eq option_node.id
    end
  end
end
