require 'rails_helper'

describe Response do
  it "cache key" do
    user = create(:user)
    form = create(:form, question_types: %w[integer])
    form.publish!

    # ensure key changes on edits, creates, and deletes
    r1 = create(:response, user: user, form: form, answer_values: [1])
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
    form = create(:form, question_types: %w[integer])
    form.root_questionings.first.update_attribute(:required, true)
    form.publish!
    form.reload

    # Submit answer with first (and only) answer empty
    # This should show up as a missing response.
    invalid_response = build(:response, user: user, form: form, answer_values: [""])
    expect(invalid_response.valid?).to eq(false)
    expect{ invalid_response.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "incomplete response will save if it is marked as incomplete" do
    user = create(:user)
    form = create(:form, question_types: %w[integer])
    form.root_questionings.first.required = true
    form.publish!
    form.reload
    expect{ create(:response, user: user, form: form, incomplete: true) }.not_to raise_error
  end

  it "a user can checkout a response" do
    user = create(:user)
    response = build(:response)

    expect(response.checked_out_at).to be_nil
    expect(response.checked_out_by_id).to be_nil

    Timecop.freeze(Date.today) do
      response.check_out!(user)
      expect(Time.now).to eq(response.checked_out_at)
      expect(response.checked_out_by).to eq(user)
    end
  end

  it "a users previous checkout will be removed if they have more than one checkout" do
    user = create(:user)

    Timecop.freeze(Date.today) do
      r_previous = create(:response, checked_out_at: Time.now, checked_out_by: user)
      r_new = build(:response)

      expect(r_new.checked_out_at).to be_nil
      expect(r_new.checked_out_by_id).to be_nil

      r_new.check_out!(user)
      r_previous.reload

      expect(Time.zone.parse(DateTime.now.to_s)).to eq(r_new.checked_out_at)
      expect(r_new.checked_out_by).to eq(user)

      expect(r_previous.checked_out_at).to be_nil
      expect(r_previous.checked_out_by_id).to be_nil
    end
  end

  context "responses count" do
    let!(:user) { create(:user) }
    let!(:form) { create(:form, question_types: %w[integer]) }
    let!(:response) { create(:response, user: user, form: form, answer_values: %w[1]) }

    describe "updates response count correctly" do
      it "on response deletion after form reload" do
        response.destroy
        expect(form.reload.responses_count).to eq(0)
      end

      it "on response creation" do
        create(:response, user: user, form: form, answer_values: %w[1])
        expect(form.responses_count).to eq(2)
      end
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
      expect(ResponseNode.count).to eq 0
      expect(Answer.count).to eq 0
      expect(Choice.all.count).to eq 0
      expect(Media::Image.all.count).to eq 0
      response # create response
      # 21 response nodes comes from:
      # 12 answers, 3 inner grps, 2 inner grp sets, 2 outer grp, 1 outer  grp set, 1 root grp
      expect(ResponseNode.count).to eq 21
      expect(Answer.count).to eq 12
      expect(Choice.count).to be > 0
      expect(Media::Image.count).to be > 0

      response.destroy
      expect(ResponseNode.count).to eq 12
      expect(Answer.count).to eq 0
      expect(Choice.count).to eq 0
      expect(Media::Image.count).to eq 0
    end
  end
end
