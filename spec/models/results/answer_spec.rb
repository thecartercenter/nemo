require "spec_helper"

describe Answer do
  it_behaves_like "has a uuid"

  describe "#media_object_id=" do
    context "with existing media object" do
      let(:object) { create(:media_image) }
      let(:answer) { Answer.new(media_object_id: object.id) }

      it "should find and associate with media object" do
        expect(answer.media_object).to eq object
        expect(answer.media_object_id).to eq object.id
      end
    end

    it "should fail silently if object not found" do
      answer = Answer.new(media_object_id: 123)
      expect(answer.media_object).to be_nil
      expect(answer.media_object_id).to be_nil
    end
  end
end
