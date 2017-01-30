require 'spec_helper'

describe UserBatch do
  let(:mission) { get_mission }

  it "creates users with varying amounts of info" do
    ub = create_user_batch("varying_info.xlsx")
    expect(ub).to be_succeeded

    assert_user_attribs(ub.users[0], login: "a.bob", name: 'A Bob',
      phone: '+2279182137', phone2: nil, email: 'a@bc.com')
    assert_user_attribs(ub.users[1], login: "bcod", name: 'Bo Cod',
      phone: nil, phone2: nil, email: 'b@co.com')
    assert_user_attribs(ub.users[2], login: "flim.flo", name: 'Flim Flo',
      phone: '+123456789', phone2: nil, email: 'f@fl.com')
    assert_user_attribs(ub.users[3], login: "shobo", name: 'Sho Bo',
      phone: nil, phone2: nil, email: 'd@ef.stu')
    assert_user_attribs(ub.users[4], login: "clo", name: 'Cha Lo',
      phone: '+983755482', phone2: '+9837494434', email: 'ch@lo.com')

    expect(User.count).to eq 5
    expect(Assignment.count).to eq 5
  end

  it "creates more than 1000 users in different batches" do
    ub = create_user_batch("user_batch_2500.xlsx")
    expect(ub).to be_succeeded

    expect(User.count).to eq 2499
    expect(Assignment.count).to eq 2499
  end

  it "creates users from csv" do
    ub = create_user_batch("user_batch_2500.csv")
    expect(ub).to be_succeeded

    expect(User.count).to eq 2499
    expect(Assignment.count).to eq 2499
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

  context "when checking validation errors on spreadsheet" do
    it "handles validation errors gracefully" do
      # create batch that should raise too short phone number error
      ub = create_user_batch("validation_errors.xlsx")
      expect(ub).not_to be_succeeded

      expect(ub.users[0].errors.full_messages.join).to match(/at least \d+ digits/)
    end

    it "checks for phone uniqueness on both numbers" do
      ub = create_user_batch("phone_problems.xlsx")
      expect(ub).not_to be_succeeded

      error_messages = ub.errors.messages.values

      expect(error_messages.length).to eq 4
      expect(error_messages[0]).to eq ["Row 2: Main Phone: Please enter a unique value."]
      expect(error_messages[1]).to eq ["Row 4: Main Phone: Please enter a unique value."]
      expect(error_messages[2]).to eq ["Row 5: Alternate Phone: Please enter a unique value."]
      expect(error_messages[3]).to eq ["Row 5: Main Phone: Please enter a unique value."]
    end

    it "checks for email uniqueness" do
      ub = create_user_batch("email_problems.xlsx")
      expect(ub).not_to be_succeeded

      error_messages = ub.errors.messages.values

      expect(error_messages.length).to eq 3
      expect(error_messages[0]).to eq ["Row 2: Email: Please enter a unique value."]
      expect(error_messages[1]).to eq ["Row 3: Email: Please enter a unique value."]
      expect(error_messages[2]).to eq ["Row 6: Email: Please enter a unique value."]
    end
  end

  context "when checking uniqueness on db" do
    before do
      create(:user, login: 'a.bob', name: 'A Bob', phone: '+2279182137', phone2: nil, email: 'a@bc.com')
      create(:user, phone: '+9837494434', phone2: '+983755482')
    end

    it "checks for login, email and phones repetitions" do
      ub = create_user_batch("varying_info.xlsx")
      expect(ub).not_to be_succeeded

      error_messages = ub.errors.messages.values

      expect(error_messages.length).to eq 5
      expect(error_messages[0]).to eq ["Row 2: Email: Please enter a unique value."]
      expect(error_messages[1]).to eq ["Row 2: Username: Please enter a unique value."]
      expect(error_messages[2]).to eq ["Row 2: Main Phone: Please enter a unique value."]
      expect(error_messages[4]).to eq ["Row 6: Main Phone: Please enter a unique value."]
      expect(error_messages[3]).to eq ["Row 6: Alternate Phone: Please enter a unique value."]
    end
  end

  private

  def assert_user_attribs(user, attribs)
    # make sure user is valid (no need to call valid? since it all validations were set during import)
    expect(user.errors.empty?).to be_truthy

    # check attribs
    expect(user).to have_attributes(attribs)
  end

  def fixture(name)
    File.expand_path("../../fixtures/user_batches/#{name}", __FILE__)
  end

  def create_user_batch(fixture_file)
    ub = UserBatch.new(file: fixture(fixture_file))
    ub.create_users(mission)
    ub
  end
end
