shared_examples_for 'admin abilities in mission mode' do
  before(:all) do
    @ability = Ability.new(user: @user, mode: 'mission', mission: get_mission)
  end

  it 'should allow edit profile' do
    expect(@ability).to be_able_to(:update, @user)
  end

  it 'should not allow adminify self' do
    expect(@ability).not_to be_able_to(:adminify, @user)
  end

  it 'should allow adminify others' do
    expect(@ability).to be_able_to(:adminify, @user2)
  end

  it 'should allow changing own assignments' do
    expect(@ability).to be_able_to(:change_assignments, @user)
  end
end
