require 'rails_helper'

describe Question do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
    before do
      @orig = create(:question, qtype_name: 'select_one', is_standard: true)
      @copy = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
      @orig.reload
    end

    context 'when replicating directly and copy exists in mission' do
      before do
        @copy2 = @orig.replicate(mode: :to_mission, dest_mission: @mission2)
      end

      it 'should make new copy but reuse option set' do
        expect(@copy).not_to eq @copy2
        expect(@copy.option_set).to eq @copy2.option_set
      end
    end

    describe 'code sync' do
      context 'when no conflicts' do
        before do
          @orig.update_attributes!(code: 'NewCode')
        end

        it 'should sync' do
          expect(@copy.reload.code).to eq 'NewCode'
        end
      end

      context 'when new code conflicts with existing question in mission' do
        before do
          # This question will conflict, but is not a copy.
          create(:question, qtype_name: 'text', code: 'NewCode', mission: @mission2)
          @orig.update_attributes!(code: 'NewCode')
        end

        it 'should sync' do
          expect(@orig.reload.code).to eq 'NewCode'
          expect(@copy.reload.code).to eq 'NewCode2'
        end
      end

      context 'for non standard-mission copies' do
        before do
          @orig = FactoryGirl.create(:question, code: 'Foo', is_standard: true)
          @copy = @orig.replicate(mode: :clone)
          @orig.reload.update_attributes!(code: 'NewCode')
        end

        it 'should not sync' do
          expect(@copy.reload.code).to eq 'Foo2'
        end
      end
    end
  end

  describe 'promote' do
    before do
      @orig = create(:question, qtype_name: 'select_one')
      @std = @orig.replicate(:mode => :promote)
    end

    it 'should work' do
      expect(@std.is_standard?).to be true
      expect(@std.option_set.is_standard?).to be true
      expect(@std.mission).to be_nil
      expect(@std).not_to eq @orig
      expect(@std.option_set).not_to eq @orig.option_set

      # originals should not have standard links
      expect(@orig.standard).to be_nil
      expect(@orig.option_set.standard).to be_nil
    end
  end

  context 'old tests' do
    it "replicating a question within a mission should change the code" do
      q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo')
      q2 = q.replicate(:mode => :clone)
      expect(q2.code).to eq('Foo2')
      q3 = q2.replicate(:mode => :clone)
      expect(q3.code).to eq('Foo3')
      q4 = q3.replicate(:mode => :clone)
      expect(q4.code).to eq('Foo4')
    end

    it "replicating a standard question should not change the code" do
      q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo', :is_standard => true)
      q2 = q.replicate(:mode => :to_mission, :dest_mission => get_mission)
      expect(q2.code).to eq(q.code)
      q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo1', :is_standard => true)
      q2 = q.replicate(:mode => :to_mission, :dest_mission => get_mission)
      expect(q2.code).to eq(q.code)
    end

    it "replicating a question should not replicate the key field" do
      q = FactoryGirl.create(:question, :qtype_name => 'integer', :key => true)
      q2 = q.replicate(:mode => :clone)

      expect(q).not_to eq q2
      expect(q.key).not_to eq q2.key
    end

    it "replicating a select question within a mission should not replicate the option set" do
      q = FactoryGirl.create(:question, :qtype_name => 'select_one')
      q2 = q.replicate(:mode => :clone)
      expect(q).not_to eq q2
    end

    it "replicating a standard select question should replicate the option set" do
      q = FactoryGirl.create(:question, :qtype_name => 'select_one', :is_standard => true)
      q2 = q.replicate(:mode => :to_mission, :dest_mission => get_mission)

      expect(q).not_to eq q2
      expect(q.option_set).not_to eq q2.option_set
      expect(q.option_set.options.first).not_to eq q2.option_set.options.first
      expect(q2.option_set.mission).not_to eq nil
    end

    it "replicating question with short code that ends in zero should work" do
      q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'q0')
      q2 = q.replicate(:mode => :clone)
      expect(q2.code).to eq('q1')
    end

    it "name should be replicated on create" do
      q = FactoryGirl.create(:question, :is_standard => true, :name => 'Foo')
      q2 = q.replicate(:mode => :to_mission, :dest_mission => get_mission)
      expect(q2.name).to eq('Foo')
      expect(q2.canonical_name).to eq('Foo')
    end
  end
end
