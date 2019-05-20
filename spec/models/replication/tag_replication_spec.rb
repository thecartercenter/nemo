# frozen_string_literal: true

require "rails_helper"

describe "replicating questions with tags" do
  let(:mission) { create(:mission) }
  let(:orig_tag1) { create(:tag, name: "a", mission: orig_mission) }
  let(:orig_tag2) { create(:tag, name: "b", mission: orig_mission) }
  let(:orig_q) do
    create(:question, mission: orig_mission, qtype_name: "text", tags: [orig_tag1, orig_tag2])
  end

  describe "to_mission" do
    let(:orig_mission) { nil }
    let(:copy_q) { orig_q.replicate(mode: :to_mission, dest_mission: mission) }

    context "basic" do
      it "should replicate tag when replicates a standard library question to a mission" do
        orig_q.reload
        expect(orig_q.id).not_to eq(copy_q.id)
        expect(copy_q.tags.count).to eq(2)
        [orig_tag1, orig_tag2].each do |orig_tag|
          new_tag = find_tag_by_name(copy_q, orig_tag.name)
          expect(new_tag.id).not_to eq(orig_tag.id)
          expect(new_tag.name).to eq(orig_tag.name)
          expect(new_tag.mission).to eq(mission)
        end
      end
    end

    context "conflicting tag exists in mission" do
      let!(:pre_existing_tag) { Tag.create!(name: "a", mission: mission) }
      let(:a_tag_for_copy) { find_tag_by_name(copy_q, "a") }
      let(:b_tag_for_copy) { find_tag_by_name(copy_q, "b") }

      it "should use the existing tag" do
        expect(orig_q.id).not_to eq(copy_q.id)
        expect(Tag.count).to eq(4) # 2 original ones, pre-existing_tag, new 'b' tag made in replication
        expect(copy_q.tags.count).to eq(2)

        expect(a_tag_for_copy.id).to eq(pre_existing_tag.id)

        expect(b_tag_for_copy.id).not_to eq(orig_tag2.id)
        expect(b_tag_for_copy.name).to eq(orig_tag2.name)
        expect(b_tag_for_copy.mission).to eq(mission)
      end
    end
  end

  describe "promote" do
    let(:orig_mission) { mission }
    let(:std) { orig_q.replicate(mode: :promote) }

    context "basic" do
      it "should create new tag with mission nil" do
        orig_q.reload
        expect(orig_q.id).not_to eq(std.id)
        expect(std.tags.count).to eq(2)
        [orig_tag1, orig_tag2].each do |orig_tag|
          new_tag = find_tag_by_name(std, orig_tag.name)
          expect(new_tag.id).not_to eq(orig_tag.id)
          expect(new_tag.name).to eq(orig_tag.name)
          expect(new_tag.mission).to be_nil
        end
      end
    end

    context "conflicting standard tag exists" do
      let!(:pre_existing_tag) { Tag.create!(name: "a", mission: nil) }
      let(:a_tag_for_std) { find_tag_by_name(std, "a") }
      let(:b_tag_for_std) { find_tag_by_name(std, "b") }

      it "should use the existing tag" do
        orig_q.reload
        expect(orig_q.id).not_to eq(std.id)
        expect(Tag.count).to eq(4) # 2 original ones, pre-existing_tag, new 'b' tag made in promotion

        expect(std.tags.count).to eq(2)

        expect(a_tag_for_std.id).to eq(pre_existing_tag.id)

        expect(b_tag_for_std.id).not_to eq(orig_tag2.id)
        expect(b_tag_for_std.name).to eq(orig_tag2.name)
        expect(b_tag_for_std.mission).to be_nil
      end
    end
  end

  describe "clone" do
    let(:orig_mission) { mission }
    let(:copy_q) { orig_q.replicate(mode: :clone) }

    it "should use the existing tag in the mission" do
      orig_q.reload
      expect(orig_q.id).not_to eq(copy_q.id)
      expect(Tag.count).to eq(2) # only the two original ones, to be reused in copy_q
      expect(copy_q.tags.count).to eq(2)
      [orig_tag1, orig_tag2].each do |orig_tag|
        new_tag = find_tag_by_name(copy_q, orig_tag.name)
        expect(new_tag.id).to eq(orig_tag.id)
        expect(new_tag.name).to eq(orig_tag.name)
        expect(new_tag.mission).to eq(mission)
      end
    end
  end

  def find_tag_by_name(question, name)
    question.tags.find_by(name: name)
  end
end
