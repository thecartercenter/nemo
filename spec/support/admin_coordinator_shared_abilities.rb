shared_examples_for 'admin or coordinator shared abilities' do

  context 'in basic mode' do
    before(:all) do
      @ability = Ability.new(user: @user, mode: 'basic')
    end

    it 'should not allow index or create' do
      expect(@ability).not_to be_able_to(:index, User)
      expect(@ability).not_to be_able_to(:create, User)
    end

    context 'for self' do
      it 'should allow show and edit' do
        expect(@ability).to be_able_to(:show, @user)
        expect(@ability).to be_able_to(:update, @user)
      end

      it 'should disallow other actions' do
        expect(@ability).not_to be_able_to(:adminify, @user)
        expect(@ability).not_to be_able_to(:change_assignments, @user)
      end
    end

    context 'for other user' do
      it 'should allow nothing' do
        expect(@ability).not_to be_able_to(:index, @user2)
        expect(@ability).not_to be_able_to(:create, @user2)
        expect(@ability).not_to be_able_to(:show, @user2)
        expect(@ability).not_to be_able_to(:update, @user2)
        expect(@ability).not_to be_able_to(:change_assignments, @user2)
      end
    end
  end

  context 'in mission mode' do
    before(:all) do
      @ability = Ability.new(user: @user, mode: 'mission', mission: get_mission)
    end

    it 'should allow index and create' do
      expect(@ability).to be_able_to(:index, User)
      expect(@ability).to be_able_to(:create, User)
    end

    context 'for self' do
      it 'should allow show and edit' do
        expect(@ability).to be_able_to(:show, @user)
        expect(@ability).to be_able_to(:update, @user)
      end

      it 'should disallow other actions' do
        expect(@ability).not_to be_able_to(:adminify, @user)
      end
    end

    context 'for other user' do
      it 'should allow show, edit, and chg assign' do
        expect(@ability).to be_able_to(:show, @user2)
        expect(@ability).to be_able_to(:update, @user2)

        # The form restricts this to the current mission's role only.
        expect(@ability).to be_able_to(:change_assignments, @user2)
      end
    end
  end
end
