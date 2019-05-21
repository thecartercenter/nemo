# frozen_string_literal: true

require "rails_helper"

describe Question do
  let(:mission1) { create(:mission) }
  let(:mission2) { create(:mission) }

  describe "to_mission" do
    let(:orig) { create(:question, :standard, qtype_name: "select_one") }
    let(:copy) { orig.replicate(mode: :to_mission, dest_mission: mission2) }

    before do
      orig.reload
    end

    context "basic" do
      it "should replicate self and option set" do
        expect(orig).not_to eq(copy)
        expect(orig.option_set).not_to eq(copy.option_set)
        expect(orig.option_set.options.first).not_to eq(copy.option_set.options.first)
        expect(copy.option_set.mission).not_to eq(nil)
      end

      it "should not change code or name" do
        expect(copy.code).to eq(orig.code)
        expect(copy.name).to eq(orig.name)
        expect(copy.canonical_name).to eq(orig.canonical_name)
      end
    end

    context "when replicating directly and copy exists in mission" do
      let(:copy2) { orig.replicate(mode: :to_mission, dest_mission: mission2) }

      it "should make new copy but reuse option set" do
        expect(copy).not_to eq(copy2)
        expect(copy.option_set).to eq(copy2.option_set)
      end
    end

    describe "code sync" do
      context "when no conflicts" do
        before do
          orig.update!(code: "NewCode")
        end

        it "should sync" do
          expect(copy.reload.code).to eq("NewCode")
        end
      end

      context "when new code conflicts with existing question in mission" do
        before do
          # This question will conflict, but is not a copy.
          create(:question, qtype_name: "text", code: "NewCode", mission: mission2)
          orig.update!(code: "NewCode")
        end

        it "should sync" do
          expect(orig.reload.code).to eq("NewCode")
          expect(copy.reload.code).to eq("NewCode2")
        end
      end
    end
  end

  describe "promote" do
    let(:orig) { create(:question, qtype_name: "select_one") }
    let(:std) { orig.replicate(mode: :promote) }

    it "should work" do
      expect(std.mission).to be_nil
      expect(std).not_to eq(orig)
      expect(std.option_set).not_to eq(orig.option_set)

      # originals should not have standard links
      expect(orig.standard).to be_nil
      expect(orig.option_set.standard).to be_nil
    end
  end

  describe "clone" do
    let(:code) { "Foo" }
    let(:orig) { create(:question, qtype_name: "select_one", key: true, code: code) }
    let(:copy) { orig.replicate(mode: :clone) }

    it "should not replicate key field, option set, option nodes, or options" do
      expect(copy).not_to eq(orig)
      expect(copy.key).to be(false)
      expect(copy.option_set).to eq(orig.option_set)
      expect(copy.option_set.preordered_option_nodes).to eq(orig.option_set.preordered_option_nodes)
      expect(copy.option_set.first_level_options).to eq(orig.option_set.first_level_options)
    end

    context "with code ending in 0" do
      let(:code) { "Foo0" }

      it "should increment properly" do
        expect(copy.code).to eq("Foo1")
      end
    end

    context "for multiple clones" do
      let(:copy1) { orig.replicate(mode: :clone) }
      let(:copy2) { copy1.replicate(mode: :clone) }
      let(:copy3) { copy2.replicate(mode: :clone) }

      it "should avoid name collisions" do
        expect(copy1.code).to eq("Foo2")
        expect(copy2.code).to eq("Foo3")
        expect(copy3.code).to eq("Foo4")
      end
    end

    context "in admin mode" do
      let(:orig) { create(:question, :standard, code: code) }

      before do
        copy # Force orig & copy creation before updating orig code
        orig.reload.update!(code: "NewCode")
      end

      it "code should not sync" do
        expect(copy.reload.code).to eq("Foo2")
      end
    end
  end
end
