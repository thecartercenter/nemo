require 'spec_helper'

describe OptionSet do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
    before do
      @orig = create(:multilevel_option_set, is_standard: true)
      @copy = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
    end

    describe 'on create' do
      it 'should be copied properly' do
        expect(@copy.mission).to eq @mission2
        expect(@copy.name).to eq @orig.name
        expect(@copy.standard).to eq @orig
        expect(@copy.is_standard).to eq false
        expect(@copy.total_options).to eq 6
        expect(Option.count).to eq 12
        expect(OptionNode.count).to eq 14
      end
    end

    describe 'on update' do
      before do
        @orig.name = 'Foo'
        @orig.save_and_rereplicate!
        @copy.reload
      end

      it 'should have replicated name' do
        expect(@copy.name).to eq 'Foo'
        expect(@copy.total_options).to eq 6
      end
    end

    describe 'on update to name preexisting in dest mission' do
      before do
        create(:option_set, name: 'Foo', mission: @mission2)
        @orig.name = 'Foo'
        @orig.save_and_rereplicate!
        @copy.reload
      end

      it 'should have replicated name avoiding collision' do
        expect(@copy.name).to eq 'Foo 2'
      end
    end

    describe 'on destroy' do
      before do
        @orig.destroy_with_copies
      end

      it 'should destroy copies' do
        expect(OptionNode.exists?(@copy)).to eq false
      end
    end
  end

  describe 'promote' do
    before do
      @orig = create(:multilevel_option_set, mission: @mission1)
      @copy = @orig.replicate(mode: :promote, retain_link_on_promote: true)
    end

    it 'should create a correct copy' do
      expect(@copy.mission).to be_nil
      expect(@copy.is_standard).to eq true
      expect(@copy.standard).to be_nil
      expect(@copy.total_options).to eq 6
      expect(@copy.options.first.is_standard).to eq true
    end

    it 'should retain links' do
      expect(@orig.reload.standard).to eq @copy
    end
  end

  describe 'clone' do
    before do
      @orig = create(:multilevel_option_set, mission: @mission1)
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
