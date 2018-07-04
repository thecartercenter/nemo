require "rails_helper"

describe UserBatch, :slow do
  let(:mission) { get_mission }

  it "creates users with varying amounts of info" do
    ub = create_user_batch("varying_info.xlsx")
    expect(ub).to be_succeeded

    assert_user_attribs(ub.users[0],
      login: "a.bob", name: "A Bob", phone: "+2279182137", phone2: nil,
      gender: "man", email: "a@bc.com")
    assert_user_attribs(ub.users[1],
      login: "bcod", name: "Bo Cod", phone: nil, phone2: nil,
      gender: "woman", email: "b@co.com", nationality: "US")
    assert_user_attribs(ub.users[2],
      login: "flim.flo", name: "Flim Flo", phone: "+123456789", phone2: nil,
      birth_year: 1989, email: "f@fl.com", nationality: "ZZ")
    assert_user_attribs(ub.users[3],
      login: "shobo", name: "Sho Bo", phone: nil, phone2: nil,
      gender: "specify", gender_custom: "Genderqueer", email: "d@ef.stu")
    assert_user_attribs(ub.users[4],
      login: "clo", name: "Cha Lo", phone: "+983755482", phone2: "+9837494434",
      birth_year: nil, gender: nil, gender_custom: nil, email: "ch@lo.com", nationality: nil)

    expect(User.count).to eq 5
    expect(Assignment.count).to eq 5
  end

  # This spec was running very slowly since it was creating 2500 users!
  # Should be refactored to stub the BATCH_SIZE constant.
  # it "creates more than users in different batches" do
  #   ub = create_user_batch("batch_of_2500.xlsx")
  #   expect(ub).to be_succeeded
  #
  #   expect(User.count).to eq 2499
  #   expect(Assignment.count).to eq 2499
  # end

  it "creates users from csv" do
    ub = create_user_batch("batch_of_3.csv")
    expect(ub).to be_succeeded

    expect(User.count).to eq 3
    expect(Assignment.count).to eq 3
  end

  describe "groups" do
    let!(:group1) { create(:user_group, name: "New Mexico dragons") }
    let!(:group2) { create(:user_group, name: "Delaware whales") }

    it "works with single group" do
      ub = create_user_batch("single_group.csv")
      expect(ub).to be_succeeded
      assert_user_attribs(ub.users[0], login: "user0", user_groups: [group1])
    end

    it "works with multiple existing groups" do
      ub = create_user_batch("multiple_groups.csv")
      expect(ub).to be_succeeded
      assert_user_attribs(ub.users[1], login: "user1", user_groups: [group2, group1])
    end

    it "works with existing and non-existing groups" do
      ub = create_user_batch("multiple_groups.csv")
      ian = UserGroup.find_by(name: "I am new")
      expect(ub).to be_succeeded
      assert_user_attribs(ub.users[2], login: "user2", user_groups: [group2, group1, ian])
    end

    it "works with multiple non-existing groups" do
      ub = create_user_batch("multiple_groups.csv")
      ano = UserGroup.find_by(name: "A new one")
      hno = UserGroup.find_by(name: "Halla new one")
      expect(ub).to be_succeeded
      assert_user_attribs(ub.users[3], login: "user3", user_groups: [ano, hno])
    end
  end

  it "ignores blank lines" do
    ub = create_user_batch("blank_lines.xlsx")
    expect(ub).to be_succeeded
    expect(2).to eq(ub.users.size)
  end

  it "succeeds when headers have trailing invisible blanks" do
    ub = create_user_batch("abnormal_headers.xlsx")
    expect(ub).to be_succeeded
  end

  it "succeeds when creating users without emails" do
    ub = create_user_batch("empty_emails.xlsx")
    expect(ub).to be_succeeded
  end

  it "creates users with passwords" do
    # This file was causing users to get created with passwords.
    ub = create_user_batch("no_passwords.xlsx")
    expect(ub).to be_succeeded
    expect(User.count).to eq 29
    expect(User.all.map(&:crypted_password).any?(&:nil?)).to be false
  end

  it "works with one row" do
    ub = create_user_batch("one_row.xlsx")
    expect(ub).to be_succeeded
    expect(User.count).to eq 1
  end

  it "gracefully handles missing header row with a number in it" do
    ub = create_user_batch("missing_headers.xlsx")
    expect(ub).not_to be_succeeded
    expect(ub.errors.messages.values).to eq([["The uploaded spreadsheet has invalid headers."]])
  end

  context "when checking validation errors on spreadsheet" do
    it "handles validation errors gracefully" do
      # create batch that should raise too short phone number error
      ub = create_user_batch("validation_errors.xlsx")
      expect(ub).not_to be_succeeded

      expect(ub.users[0].errors.full_messages.join).to match(/at least \d+ digits/)
    end

    it "checks for phone uniqueness on both numbers, ignoring deleted data" do
      create(:user, :deleted, phone: "+983755482") # Decoy

      ub = create_user_batch("phone_problems.xlsx")
      expect(ub).not_to be_succeeded

      error_messages = ub.errors.messages.values
      expect(error_messages.length).to eq 4
      expect(error_messages[0]).to eq ["Row 2: Main Phone: Please enter a unique value."]
      expect(error_messages[1]).to eq ["Row 4: Main Phone: Please enter a unique value."]
      expect(error_messages[2]).to eq ["Row 5: Alternate Phone: Please enter a unique value."]
      expect(error_messages[3]).to eq ["Row 5: Main Phone: Please enter a unique value."]
    end

    it "does not check for email uniqueness" do
      ub = create_user_batch("duplicate_emails.xlsx")
      expect(ub).to be_succeeded
    end
  end

  context "when checking uniqueness on db" do
    before do
      # a@bc.com also exists in fixure but we don't care about email uniqueness
      create(:user, login: "a.bob", name: "A Bob", phone: "+2279182137", phone2: nil, email: "a@bc.com")
      create(:user, phone: "+9837494434", phone2: "+983755482")
    end

    it "checks for duplicate usernames and phones" do
      ub = create_user_batch("varying_info.xlsx")
      expect(ub).not_to be_succeeded
      error_messages = ub.errors.messages.values

      expect(error_messages.length).to eq 4
      expect(error_messages[0]).to eq ["Row 2: Username: Please enter a unique value."]
      expect(error_messages[1]).to eq ["Row 2: Main Phone: Please enter a unique value."]
      expect(error_messages[2]).to eq ["Row 6: Alternate Phone: Please enter a unique value."]
      expect(error_messages[3]).to eq ["Row 6: Main Phone: Please enter a unique value."]
    end
  end

  private

  def assert_user_attribs(user, attribs)
    # make sure user is valid (no need to call valid? since it all validations were set during import)
    expect(user.errors.empty?).to be_truthy

    # check attribs
    expect(user).to have_attributes(attribs)
  end

  def create_user_batch(fixture_file)
    ub = UserBatch.new(file: user_batch_fixture(fixture_file))
    ub.create_users(mission)
    ub
  end
end
