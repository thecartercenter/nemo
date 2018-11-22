# frozen_string_literal: true

require "rails_helper"

describe "replicating questions with tags" do
  let(:mission) { create(:mission) }

  describe "to_mission" do
    let(:orig_tag1) {create(:tag, name: 'a', mission: nil)}
    let(:orig_tag2) {create(:tag, name: 'b', mission: nil)}
    #add a second tag to question
    let(:orig_q) { create(:question, qtype_name: "text", is_standard: true, tags: [orig_tag1, orig_tag2]) }
    let!(:copy_q) { orig_q.replicate(mode: :to_mission, dest_mission: mission) }

    before do
      orig_q.reload
    end

    context "basic" do
      it "should replicate tag when replicates a standard library question to a mission" do
        expect(orig_q.id).not_to eq(copy_q.id)
        expect(copy_q.tags.count).to eq 2
        [orig_tag1, orig_tag2].each_with_index do |orig_tag, i|
          new_tag = copy_q.tags.find {|new_t| new_t.name == orig_tag.name}
          expect(new_tag.id).not_to eq(orig_tag.id)
          expect(new_tag.name).to eq(orig_tag.name)
          expect(new_tag.mission).to eq(mission)
        end

      end
    end
  end
end
