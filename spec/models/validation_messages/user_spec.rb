require 'spec_helper'

describe User do
  before { I18n.locale = :en }

  context 'with assignment validation error' do
    before do
      @user = build(:user)
      @user.assignments[0].mission = nil
      @user.assignments[0].role = nil
      @user.save
    end

    it 'assignment validation message should be correct' do
      expect(@user.errors['assignments.role']).to eq ['is required.']
      expect(@user.errors['assignments.mission']).to eq ['is required.']
    end
  end
end