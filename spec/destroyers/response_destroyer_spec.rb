# frozen_string_literal: true

require "rails_helper"

describe ResponseDestroyer do
  let(:ability) { Ability.new(user: create(:admin), mission: get_mission) }
  let(:result) {
    res = described_class.new(scope: scope, ability: ability).destroy!
    puts "Done"
    res
  }

  context "with responses" do
    let(:form) do
      create(:form, question_types: [
        "select_one", "select_one", "select_one", "select_one", "select_one", "select_one", "select_one", "select_one", "select_one", "select_one", "select_one",
        "select_multiple", %w[integer integer], "image"])
    end
    let!(:responses) do
      # We don't use create_list because that wouldn't create new images each time.
      Array.new(4) do
        create(:response, form: form, answer_values: [
          "Cat", "Cat", "Cat", "Cat", "Cat", "Cat", "Cat", "Cat", "Cat", "Cat", "Cat",
          %w[Cat Dog], [1, 2], create(:media_image)])
      end
    end
    let(:decoy) { responses[0] }
    let(:scope) { Response.where.not(id: decoy.id) }

    # TODO: Validate that it runs fast enough.
    it "ignores decoy, deletes others completely" do
      Rails.logger.debug "ABOUT TO DESTROY"
      now = Time.zone.now
      expect(result).to eq(destroyed: 3, skipped: 0, deactivated: 0)
      puts "@@@ Took: #{Time.zone.now - now}"
      expect(Response.count).to eq(1)
      expect(Answer.count).to eq(5)
      expect(ResponseNode.count).to eq(7)
      expect(Choice.count).to eq(2)
      expect(Media::Object.count).to eq(1)
      # expect { 3.times { Settings.for_mission(nil) } }.to make_database_queries(count: 3)
      expect(SqlRunner.instance.run("SELECT COUNT(*) FROM answer_hierarchies")[0]["count"]).to eq(15)
    end
  end

  context "with no responses" do
    let(:scope) { Response.all }

    it "does nothing" do
      expect(result).to eq(destroyed: 0, skipped: 0, deactivated: 0)
    end
  end
end
