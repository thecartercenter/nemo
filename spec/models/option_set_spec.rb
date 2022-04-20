# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: option_sets
#
#  id                   :uuid             not null, primary key
#  allow_coordinates    :boolean          default(FALSE), not null
#  geographic           :boolean          default(FALSE), not null
#  level_names          :jsonb
#  name                 :string(255)      not null
#  sms_guide_formatting :string(255)      default("auto"), not null
#  standard_copy        :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  mission_id           :uuid
#  original_id          :uuid
#  root_node_id         :uuid
#
# Indexes
#
#  index_option_sets_on_geographic           (geographic)
#  index_option_sets_on_mission_id           (mission_id)
#  index_option_sets_on_name_and_mission_id  (name,mission_id) UNIQUE
#  index_option_sets_on_original_id          (original_id)
#  index_option_sets_on_root_node_id         (root_node_id) UNIQUE
#
# Foreign Keys
#
#  option_sets_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  option_sets_option_node_id_fkey  (root_node_id => option_nodes.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe OptionSet do
  include OptionNodeSupport

  it "should get constructed properly" do
    os = create(:option_set, option_names: :multilevel)
    # This assertion checks that option_set and mission get cascaded properly.
    expect_node([["Animal", %w[Cat Dog]], ["Plant", %w[Tulip Oak]]], os.root_node)
    expect(Option.count).to eq(6)
    expect(OptionNode.count).to eq(7)
  end

  it "should get constructed properly if standard" do
    os = create(:option_set, :standard)
    expect_node(%w[Cat Dog], os.root_node)
  end

  it "should get updated properly" do
    os = create(:option_set)
    os.update!(children_attribs: OptionNodeSupport::MULTILEVEL_ATTRIBS)
    expect_node([["Animal", %w[Cat Dog]], ["Plant", %w[Tulip Oak]]], os.reload.root_node)
  end

  it "should be destructible" do
    os = create(:option_set)
    os.destroy
    expect(OptionSet.exists?(os.id)).to be(false)
    expect(OptionNode.where(option_set_id: os.id).count).to eq(0)
  end

  describe "options" do
    before { @set = create(:option_set, option_names: :multilevel) }

    it "should delegate to option node child options" do
      expect(@set.root_node).to receive(:child_options)
      @set.options
    end
  end

  describe "core_changed?" do
    before { @set = create(:option_set) }

    it "should return true if name changed" do
      @set.name = "Foobar"
      expect(@set.core_changed?).to eq(true)
    end

    it "should return false if name didnt change" do
      expect(@set.core_changed?).to eq(false)
    end
  end

  describe "levels" do
    it "should be nil for single level set" do
      set = create(:option_set)
      expect(set.levels).to be_nil
    end

    it "should be correct for multi level set" do
      set = create(:option_set, option_names: :multilevel)
      expect(set.levels[0].name).to eq("Kingdom")
      expect(set.levels[1].name).to eq("Species")
    end
  end

  describe "worksheet_name" do
    it "should return the original name if valid" do
      set = create(:option_set)
      expect(set.worksheet_name).to eq(set.name)
    end

    it "should return a replaced name if invalid" do
      set = create(:option_set, name: 'My Options?: ~*[Yes/No:No\Yes]*~')
      expect(set.worksheet_name.size).to be <= 31
      expect(set.worksheet_name).to eq("My Options- ~∗(Yes-No-No-Ye...")
    end
  end

  describe "fetch_by_shortcode" do
    let!(:option_set) { create(:option_set, option_names: :super_multilevel) }
    let!(:option_node) { option_set.preordered_option_nodes.last }

    it "should fetch the correct node from shortcode" do
      fetched_node = option_set.fetch_by_shortcode("e")
      expect(fetched_node.id).to eq(option_node.id)
    end
  end

  describe "arrange_as_rows" do
    let!(:option_set) { create(:option_set, option_names: :multilevel) }

    context "with missing option node" do
      before do
        option_set.root_node.c[1].children.destroy_all
        expect_node([["Animal", %w[Cat Dog]], ["Plant", []]], option_set.root_node)
        option_set.reload
      end

      it "returns all rows of equal length" do
        lengths = option_set.arrange_as_rows.map(&:length)
        expect(lengths).to eq([4, 4, 4])
      end
    end
  end

  describe "name validations" do
    let(:mission) { create(:mission) }
    let!(:likert) { create(:option_set, name: "likert", mission: mission) }

    context "create duplicate name in same mission" do
      it "should fail" do
        set = build(:option_set, name: "likert", mission: mission)
        expect(set).not_to be_valid
      end
    end

    context "create duplicate name in different mission" do
      it "should create option set with same name" do
        set = create(:option_set, name: "likert", mission_id: "aaa-2222")
        expect(set.name).to eq("likert")
      end
    end
  end

  describe "destruction" do
    let!(:option_set) { create(:option_set) }

    context "without associations" do
      it "destroys cleanly" do
        option_set.destroy
      end
    end

    context "with question" do
      let!(:question) { create(:question, option_set: option_set) }

      it "raises DeleteRestrictionError" do
        expect { option_set.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError) do |e|
          # We test the exact wording of the error because the last word is sometimes used to
          # lookup i18n strings.
          expect(e.to_s).to eq("Cannot delete record because of dependent questions")
        end
      end
    end

    context "with data" do
      let!(:form) { create(:form, question_types: %w[select_one]) }
      let(:option_set) { form.c[0].option_set }
      let!(:response) { create(:response, form: form, answer_values: %w[Cat]) }

      it "raises DeleteRestrictionError" do
        expect { option_set.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError) do |e|
          # We test the exact wording of the error because the last word is sometimes used to
          # lookup i18n strings.
          expect(e.to_s).to eq("Cannot delete record because of dependent answers")
        end
      end
    end
  end
end
