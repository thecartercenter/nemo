require "spec_helper"

describe Form do

  context "API User" do
    before do
      @api_user = FactoryGirl.create(:user)
      @mission = FactoryGirl.create(:mission, name: "test mission")
      @form = FactoryGirl.create(:form, mission: @mission, name: "something", access_level: 'protected')
      @form.whitelist_users.create(user_id: @api_user.id)
    end

    it "should return true for user in whitelist" do
      expect(@form.api_user_id_can_see?(@api_user.id)).to be_truthy
    end

    it "should return false for user not in whitelist" do
      other_user = FactoryGirl.create(:user)
      expect(@form.api_user_id_can_see?(other_user.id)).to be_falsey
    end
  end

  describe 'update_ranks' do
    before do
      # Create form with condition (#3 referring to #2)
      @form = create(:form, question_types: %w(integer select_one integer))
      @qings = @form.root_questionings
      @qings[2].create_condition(ref_qing: @qings[1], op: 'eq', option: @qings[1].options[0])

      # Move question #1 down to position #3 (old #2 and #3 shift up one).
      @old_ids = @qings.map(&:id)

      # Without this, this test was not raising a ConditionOrderingError that was getting raised in the wild.
      # ORM can be a pain sometimes!
      @form.reload

      @form.update_ranks(@old_ids[0] => 3, @old_ids[1] => 1, @old_ids[2] => 2)
      @form.save!
    end

    it 'should update ranks and not raise order invalidation error' do
      expect(@form.reload.questionings.map(&:id)).to eq [@old_ids[1], @old_ids[2], @old_ids[0]]
    end
  end

  describe 'pub_changed_at' do
    before do
      @form = create(:form)
    end

    it 'should be nil on create' do
      expect(@form.pub_changed_at).to be_nil
    end

    it 'should be updated when form published' do
      @form.publish!
      expect(@form.pub_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it 'should be updated when form unpublished' do
      publish_and_reset_pub_changed_at(save: true)
      @form.unpublish!
      expect(@form.pub_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it 'should not be updated when form saved otherwise' do
      publish_and_reset_pub_changed_at
      @form.name = 'Something else'
      @form.save!
      expect(@form.pub_changed_at).not_to be_within(5.minutes).of(Time.zone.now)
    end
  end

  describe 'needs_odk_manifest?' do
    context 'for form with single level option sets only' do
      before { @form = create(:form, question_types: %w(select_one)) }
      it 'should return false' do
        expect(@form.needs_odk_manifest?).to be false
      end
    end
    context 'for form with multi level option set' do
      before { @form = create(:form, question_types: %w(select_one multi_level_select_one)) }
      it 'should return true' do
        expect(@form.needs_odk_manifest?).to be true
      end
    end
  end

  describe 'odk_download_cache_key' do
    before do
      @form = create(:form)
      publish_and_reset_pub_changed_at
    end

    it 'should be correct' do
      expect(@form.odk_download_cache_key).to eq "odk-form/#{@form.id}-#{@form.pub_changed_at}"
    end
  end

  describe 'odk_index_cache_key' do
    before do
      @form = create(:form)
      @form2 = create(:form)
      publish_and_reset_pub_changed_at(save: true)
      publish_and_reset_pub_changed_at(form: @form2, diff: 30.minutes, save: true)
    end

    context 'for mission with forms' do
      it 'should be correct' do
        expect(Form.odk_index_cache_key(mission: get_mission)).to eq "odk-form-list/mission-#{get_mission.id}/#{@form2.pub_changed_at.utc.to_s(:cache_datetime)}"
      end
    end

    context 'for mission with no forms' do
      before do
        @mission2 = create(:mission)
        create(:form, mission: @mission2) # Unpublished
      end
      it 'should be correct' do
        expect(Form.odk_index_cache_key(mission: @mission2)).to eq "odk-form-list/mission-#{@mission2.id}/no-pubd-forms"
      end
    end
  end

  context 'root_group' do
    before do
      @mission = create(:mission)
    end

    it 'has a root group when created from factory' do
      form = create(:form, mission: @mission, question_types: ['integer', ['text', 'text'], 'text'])
      expect(form.root_group).to_not be_nil
    end
  end

  context 'ancestry' do
    before do
      @mission = create(:mission)
      @form = create(:form, mission: @mission, question_types: ['integer', ['text', 'text'], 'text'])
    end

    it 'has 3 children' do
      expect(@form.root_group.children.count).to eq 3
    end

    it 'has one subgroup with two children' do
      expect(@form.root_group.children[1].children.count).to eq 2
    end
  end

  def publish_and_reset_pub_changed_at(options = {})
    f = options[:form] || @form
    f.publish!
    f.pub_changed_at -= (options[:diff] || 1.hour)
    f.save! if options[:save]
  end
end
