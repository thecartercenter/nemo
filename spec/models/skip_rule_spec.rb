require 'spec_helper'

describe SkipRule do
  it_behaves_like "has a uuid"

  describe "normalization" do
    describe "rank" do
      let(:qing) { create(:questioning) }
      let(:skip_rule) { create(:skip_rule, source_item: qing) }
      let!(:decoy_rule) { create(:skip_rule) } # On a different qing, ensures acts_as_list is scoped.
      subject { skip_rule.rank }

      context "when no other rules for this qing" do
        it { is_expected.to eq 1 }
      end

      context "when two other rules for this qing" do
        let!(:other_skip_rules) { create_list(:skip_rule, 2, source_item: qing) }
        it { is_expected.to eq 3 }
      end
    end
  end
end
