require "spec_helper"

describe Question do
  describe "search" do
    def search(query)
      Question.do_search(Question, query)
    end

    before do
      @questions = [
        create(:question, name: "Manchego", code: "Navajo"),
        create(:question, qtype_name: 'text'),
      ]
    end

    it "partial title search" do
      expect(search 'manche').to eq [@questions[0]]
    end

    it "partial code search" do
      expect(search 'code: nav').to eq [@questions[0]]
    end

    it "question type search" do
      expect(search 'type: text').to eq [@questions[1]]
    end
  end
end
