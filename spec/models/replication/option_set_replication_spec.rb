require 'spec_helper'

describe OptionSet do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
    before do
      @orig = create(:option_set, multi_level: true, is_standard: true)
      @copy = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
    end

    it 'should be copied properly' do
      expect(@copy.mission).to eq @mission2
      expect(@copy.name).to eq @orig.name
      expect(@copy.standard).to eq @orig
      expect(@copy.is_standard).to eq false
      expect(@copy.total_options).to eq 6

      # Ensure option set gets correct root node id.
      expect(@copy.root_node_id).not_to be_nil
      expect(@copy.root_node_id).not_to eq @orig.root_node_id

      # Ensure option set ID gets copied all the way down.
      expect(@copy.root_node.option_set_id).to eq @copy.id
      expect(@copy.root_node.c[0].option_set_id).to eq @copy.id
      expect(@copy.root_node.c[0].c[0].option_set_id).to eq @copy.id

      # Ensure no duplicates.
      expect(Option.count).to eq 12
      expect(OptionNode.count).to eq 14
    end

    context 'when replicating directly and copy exists in mission' do
      before do
        @copy2 = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
      end

      it 'should make new copy but reuse options' do
        expect(@copy).not_to eq @copy2
        expect(@copy.options).to eq @copy2.options
      end
    end
  end

  describe 'promote with link' do
    before do
      @orig = create(:option_set, multi_level: true, mission: @mission1)
      @copy = @orig.replicate(mode: :promote, retain_link_on_promote: true)
    end

    it 'should create a correct copy' do
      expect(@copy.mission).to be_nil
      expect(@copy.is_standard).to eq true
      expect(@copy.standard).to be_nil
      expect(@copy.total_options).to eq 6
    end

    it 'should retain links' do
      expect(@orig.reload.standard).to eq @copy
    end
  end

  describe 'clone' do
    before do
      @orig = create(:option_set, multi_level: true, mission: @mission1)
      @copy = @orig.replicate(mode: :clone)
    end

    it 'should make correct copy' do
      expect(@copy.mission).to eq @mission1
      expect(@copy.is_standard).to eq false
      expect(@copy.standard).to be_nil
      expect(@copy.total_options).to eq 6
    end
  end
end
