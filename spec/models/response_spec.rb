# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: responses
#
#  id                :uuid             not null, primary key
#  cached_json       :jsonb
#  checked_out_at    :datetime
#  dirty_dupe        :boolean          default(TRUE), not null
#  dirty_json        :boolean          default(TRUE), not null
#  incomplete        :boolean          default(FALSE), not null
#  modifier          :string
#  odk_hash          :string(255)
#  reviewed          :boolean          default(FALSE), not null
#  reviewer_notes    :text
#  shortcode         :string(255)      not null
#  source            :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  checked_out_by_id :uuid
#  device_id         :string
#  form_id           :uuid             not null
#  mission_id        :uuid             not null
#  old_id            :integer
#  reviewer_id       :uuid
#  user_id           :uuid             not null
#
# Indexes
#
#  index_responses_on_checked_out_at        (checked_out_at)
#  index_responses_on_checked_out_by_id     (checked_out_by_id)
#  index_responses_on_created_at            (created_at)
#  index_responses_on_form_id               (form_id)
#  index_responses_on_form_id_and_odk_hash  (form_id,odk_hash) UNIQUE
#  index_responses_on_mission_id            (mission_id)
#  index_responses_on_reviewed              (reviewed)
#  index_responses_on_reviewer_id           (reviewer_id)
#  index_responses_on_shortcode             (shortcode) UNIQUE
#  index_responses_on_updated_at            (updated_at)
#  index_responses_on_user_id               (user_id)
#  index_responses_on_user_id_and_form_id   (user_id,form_id)
#
# Foreign Keys
#
#  responses_checked_out_by_id_fkey  (checked_out_by_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_form_id_fkey            (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_mission_id_fkey         (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_reviewer_id_fkey        (reviewer_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_user_id_fkey            (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe Response do
  it "has valid factory" do
    create(:response)
  end

  it "cache key" do
    user = create(:user)
    form = create(:form, :live, question_types: %w[integer])

    # ensure key changes on edits, creates, and deletes
    _r1 = create(:response, user: user, form: form, answer_values: [1])
    key1 = Response.per_mission_cache_key(get_mission)

    # create
    r2 = create(:response, user: user, form: form, answer_values: [1])
    key2 = Response.per_mission_cache_key(get_mission)
    expect(key2).not_to eq(key1)

    # edit
    Timecop.travel(10.seconds) do
      r2.root_node.c.first.update(value: 2)
      key3 = Response.per_mission_cache_key(get_mission)
      expect(key3).not_to eq(key2)
    end

    # destroy
    r2.destroy
    key4 = Response.per_mission_cache_key(get_mission)
    expect(key4).not_to eq(key2)
  end

  it "incomplete response will not save if it is not marked as incomplete" do
    user = create(:user)
    form = create(:form, :live, question_types: %w[integer])
    form.c[0].update!(required: true)
    form.reload

    # Submit answer with first (and only) answer empty
    # This should show up as a missing response.
    invalid_response = build(:response, user: user, form: form, answer_values: [""])
    expect(invalid_response.valid?).to eq(false)
    expect { invalid_response.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "incomplete response will save if it is marked as incomplete" do
    user = create(:user)
    form = create(:form, :live, question_types: %w[integer])
    form.c[0].update!(required: true)
    form.reload
    expect { create(:response, user: user, form: form, incomplete: true) }.not_to raise_error
  end

  it "a user can checkout a response" do
    user = create(:user)
    response = build(:response)

    expect(response.checked_out_at).to be_nil
    expect(response.checked_out_by_id).to be_nil

    Timecop.freeze(Time.zone.today) do
      response.check_out!(user)
      expect(Time.current).to eq(response.checked_out_at)
      expect(response.checked_out_by).to eq(user)
    end
  end

  it "a users previous checkout will be removed if they have more than one checkout" do
    user = create(:user)

    Timecop.freeze(Time.zone.today) do
      r_previous = create(:response, checked_out_at: Time.current, checked_out_by: user)
      r_new = build(:response)

      expect(r_new.checked_out_at).to be_nil
      expect(r_new.checked_out_by_id).to be_nil

      r_new.check_out!(user)
      r_previous.reload

      expect(r_new.checked_out_at).to eq(Time.current)
      expect(r_new.checked_out_by).to eq(user)

      expect(r_previous.checked_out_at).to be_nil
      expect(r_previous.checked_out_by_id).to be_nil
    end
  end

  context "destroying a response" do
    let(:question_types) do
      ["text", {repeating: {items: ["text", {repeating: {items: %w[text select_multiple image]}}]}}]
    end
    let(:outer_form_grp) { form.c[1] }
    let(:inner_form_grp) { outer_form_grp.c[1] }
    let(:answer_values) do # for original response
      [
        "A",
        {repeating: [
          [
            "B",
            {repeating: [["C", %w[Dog], create(:media_image)]]}
          ],
          [
            "D",
            {repeating: [["E", %w[Cat Dog], create(:media_image)], ["F", %w[Cat], create(:media_image)]]}
          ]
        ]}
      ]
    end
    let(:user) { create(:user) }
    let(:form) { create(:form, question_types: question_types) }
    let(:response) { create(:response, user: user, form: form, answer_values: answer_values) }

    it "destroys nested response tree nodes, media, choices" do
      expect(ResponseNode.count).to eq(0)
      expect(Choice.all.count).to eq(0)
      expect(Media::Image.all.count).to eq(0)
      response # create response
      # 21 response nodes comes from:
      # 12 answers, 3 inner grps, 2 inner grp sets, 2 outer grp, 1 outer  grp set, 1 root grp
      expect(ResponseNode.count).to eq(21)
      expect(Answer.count).to eq(12)
      expect(Choice.count).to be > 0
      expect(Media::Image.count).to be > 0

      response.destroy
      expect(ResponseNode.count).to eq(0)
      expect(Choice.count).to eq(0)
      expect(Media::Image.count).to eq(0)
    end
  end
end
