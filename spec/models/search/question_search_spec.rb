require "rails_helper"

describe Question do
  describe "search" do
    before do
      @questions = [
        create(:question, name_en: "How many cheeses?", name_fr: "Combien de fromages?", code: "Cheese"),
        create(:question, name_en: "Your job?", name_fr: "Votre metier?", qtype_name: "text", tags: [create(:tag, name: "employment")]),
        create(:question, name_en: "Yea or nay?", qtype_name: "select_one")
      ]
    end

    it "partial title search" do
      expect(search "cheese").to eq [@questions[0]]
      expect(search "title: many").to eq [@questions[0]]
      expect(search "fromage").to eq []
    end

    it "different locale" do
      I18n.locale = :fr
      expect(search "job").to eq []
      expect(search "metier").to eq [@questions[1]]
      I18n.locale = :en
      expect(search "job").to eq [@questions[1]]
    end

    it "partial code search" do
      expect(search "code: eese").to eq [@questions[0]]
    end

    it "question type search" do
      expect(search "type: text").to eq [@questions[1]]
      expect(search "type: select-one").to eq [@questions[2]]
    end

    it "tag search" do
      expect(search "tag: employment").to eq [@questions[1]]
    end

    it "empty search" do
      expect(search "").to match_array(@questions)
    end

    def search(query)
      Question.do_search(Question, query, nil)
    end
  end
end
