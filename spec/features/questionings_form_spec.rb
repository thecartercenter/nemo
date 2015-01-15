require 'spec_helper'

describe 'questionings form' do
  before do
    @user = create(:user, role_name: 'coordinator')
    login(@user)
  end

  context 'for mission-based' do
    before do
      @form = create(:form, question_types: %w(text text))
      @qing = @form.questionings[1]
    end

    context 'when unpublished' do
      it 'should display all fields as editable' do
        visit(edit_questioning_path(@qing, locale: 'en', mode: 'm', mission_name: get_mission.compact_name))
        expect_editable('required', true)
        expect_editable('hidden', true)
        expect_editable('condition', true)
      end
    end

    context 'when published' do
      before { @form.publish! }

      it 'should display all fields as not editable' do
        visit(edit_questioning_path(@qing, locale: 'en', mode: 'm', mission_name: get_mission.compact_name))
        expect_editable('required', false)
        expect_editable('hidden', false)
        expect_editable('condition', false)
      end
    end
  end

  context 'for unpublished std copy' do
    before do
      @std = create(:form, question_types: %w(text text), is_standard: true)
      @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
      @qing = @copy.questionings[1]
    end

    it 'should display all fields as editable' do
      visit(edit_questioning_path(@qing, locale: 'en', mode: 'm', mission_name: get_mission.compact_name))
      expect_editable('required', true)
      expect_editable('hidden', true)
      expect_editable('condition', true)
    end
  end

  def expect_editable(field, yn)
    expect(page).send(yn ? :to : :not_to, have_selector("div.form_field.questioning_#{field} .widget input"))
  end
end