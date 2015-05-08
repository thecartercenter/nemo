require 'spec_helper'

describe User do

  before do
    @mission = get_mission
    @mission.setting.load
  end

  it "creating several users with varying amounts of info should work" do
    ub = UserBatch.new(:batch => "A Bob, +2279182137, a@bc.com\nBo Cod\nFlim Flo, +2236366363\nSho Bo, d@ef.stu\nCha Lo, +983755482, +9837494434")
    ub.create_users(@mission)
    expect(ub.succeeded?).to be_truthy, "user creation failed"
    assert_user_attribs(ub.lines[0][:user], :name => 'A Bob', :phone => '+2279182137', :phone2 => nil, :email => 'a@bc.com')
    assert_user_attribs(ub.lines[1][:user], :name => 'Bo Cod', :phone => nil, :phone2 => nil, :email => nil)
    assert_user_attribs(ub.lines[2][:user], :name => 'Flim Flo', :phone => '+2236366363', :phone2 => nil, :email => nil)
    assert_user_attribs(ub.lines[3][:user], :name => 'Sho Bo', :phone => nil, :phone2 => nil, :email => 'd@ef.stu')
    assert_user_attribs(ub.lines[4][:user], :name => 'Cha Lo', :phone => '+983755482', :phone2 => '+9837494434')
  end

  it "extra tokens should be detected" do
    ub = UserBatch.new(:batch => "A Bob, Bob Bob, a@b@c.com, +2279182137, a@bc.com, +22791821225322, +2232479182137")
    ub.create_users(@mission)
    expect(ub.succeeded?).to be_falsey, "user creation should have failed"
    expect(ub.lines[0][:bad_tokens]).to eq(['Bob Bob', 'a@b@c.com', '+2232479182137'])
  end

  it "validation errors should be handled gracefully" do
    # create batch that should raise too short phone number error
    ub = UserBatch.new(:batch => "A Bob, +22791, a@bc.com\nAlan Bob")
    ub.create_users(@mission)
    expect(ub.succeeded?).to be_falsey, "user creation should have failed"
    assert_match(/at least \d+ digits/, ub.lines[0][:user].errors.full_messages.join)
  end

  it "blank lines should be ignored" do
    ub = UserBatch.new(:batch => "\n\nA Bob, +2279182137, a@bc.com\nBo Cod\n   \n\n")
    ub.create_users(@mission)
    expect(ub.succeeded?).to be_truthy, "user creation failed"
    expect(2).to eq(ub.lines.size)
  end

  it "extra commas should be ignored" do
    ub = UserBatch.new(:batch => "A Bob,, +2279182137, a@bc.com,,\nBo Cod,")
    ub.create_users(@mission)
    expect(ub.succeeded?).to be_truthy, "user creation failed"
    assert_user_attribs(ub.lines[0][:user], :name => 'A Bob', :phone => '+2279182137', :phone2 => nil, :email => 'a@bc.com')
    assert_user_attribs(ub.lines[1][:user], :name => 'Bo Cod', :phone => nil, :phone2 => nil, :email => nil)
  end

  private
    def assert_user_attribs(user, attribs)
      # make sure user is successfully created
      expect(user.valid? && !user.new_record?).to be true

      # check each attrib
      attribs.each_pair{|k,v| expect(user.send(k)).to eq(v)}
    end
end