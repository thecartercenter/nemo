require 'spec_helper'

describe User do
  let(:mission) { get_mission }

  it "creating several users with varying amounts of info should work" do
    ub = UserBatch.new(file: fixture("varying_info.xlsx"))
    ub.create_users(mission)
    expect(ub.succeeded?).to be_truthy, "user creation failed"
    assert_user_attribs(ub.users[0], name: 'A Bob', phone: '+2279182137', phone2: nil, email: 'a@bc.com')
    assert_user_attribs(ub.users[1], name: 'Bo Cod', phone: nil, phone2: nil, email: nil)
    assert_user_attribs(ub.users[2], name: 'Flim Flo', phone: '+2236366363', phone2: nil, email: nil)
    assert_user_attribs(ub.users[3], name: 'Sho Bo', phone: nil, phone2: nil, email: 'd@ef.stu')
    assert_user_attribs(ub.users[4], name: 'Cha Lo', phone: '+983755482', phone2: '+9837494434')
  end

  it "validation errors should be handled gracefully" do
    # create batch that should raise too short phone number error
    ub = UserBatch.new(file: fixture("validation_errors.xlsx"))
    ub.create_users(mission)
    expect(ub.succeeded?).to be_falsey, "user creation should have failed"
    expect(ub.users[0].errors.full_messages.join).to match(/at least \d+ digits/)
  end

  it "blank lines should be ignored" do
    ub = UserBatch.new(file: fixture("blank_lines.xlsx"))
    ub.create_users(mission)
    expect(ub.succeeded?).to be_truthy, "user creation failed"
    expect(2).to eq(ub.users.size)
  end

  private
  def assert_user_attribs(user, attribs)
    # make sure user is successfully created
    expect(user.valid? && !user.new_record?).to be true

    # check attribs
    expect(user).to have_attributes(attribs)
  end

  def fixture(name)
    File.expand_path("../../fixtures/user_batches/#{name}", __FILE__)
  end
end
