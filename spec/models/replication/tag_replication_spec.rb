# frozen_string_literal: true

require "rails_helper"

describe "replicating questions with tags" do
  let(:mission) { create(:mission) }

  describe "to_mission" do
    let(:orig_tag) {create(:tag, name: 'a', mission: nil)}
    #add a second tag to question
    let(:orig_q) { create(:question, qtype_name: "text", is_standard: true, tags: [orig_tag]) }
    let(:copy_q) { orig_q.replicate(mode: :to_mission, dest_mission: mission) }

    before do
      orig_q.reload
    end

    context "basic" do
      it "should replicate tag when replicates a standard library question to a mission" do
        expect(orig_q).not_to eq(copy_q)
        expect(orig_q.tags[0]).to eq(orig_tag)
        expect(copy_q.tags.count).to eq 1
        expect(copy_q.tags[0]).not_to eq(orig_tag)
        expect(copy_q.tags[0].mission).to eq(mission)
      end
    end
  end
end
