# frozen_string_literal: true

require "rails_helper"

describe Media::Object do
  let(:media_object) { create(:media_image) }
  let(:can_edit_response) { true }
  let(:actor) { create(:user, role_name: :enumerator) }
  let(:ability) { Ability.new(user: actor, mission: get_mission) }

  before do
    expect(ability).to receive(:can?).at_least(:once).and_wrap_original do |m, permission, obj|
      permission == :edit && obj.is_a?(Response) ? can_edit_response : m.call(permission, obj)
    end
  end

  it "anyone can create" do
    expect(ability).to be_able_to(:create, Media::Object)
  end

  describe "destroy" do
    context "with no associated answer" do
      it { expect(ability).to be_able_to(:destroy, media_object) }
    end

    context "with associated answer" do
      let!(:form) { create(:form, question_types: %w[image]) }
      let!(:response) { create(:response, form: form, answer_values: [media_object]) }

      context "when can edit associated response" do
        let(:can_edit_response) { true }
        it { expect(ability).to be_able_to(:destroy, media_object) }
      end

      context "when cannot edit associated response" do
        let(:can_edit_response) { false }
        it { expect(ability).not_to be_able_to(:destroy, media_object) }
      end
    end
  end
end
