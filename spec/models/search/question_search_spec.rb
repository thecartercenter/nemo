require "spec_helper"

describe Question do
  describe "search" do
    def search(query)
      Question.do_search(Question, query)
    end

    before do
      @questions = [
        create(:question, name: "Manchego", code: "Navajo"),
        create(:question, qtype_name: 'text', tags: [create(:tag, name: 'thriftstore')]),
      ]
    end

    it "partial title search" do
      expect(search 'manche').to eq [@questions[0]]
      expect(search 'title: manche').to eq [@questions[0]]
    end

    it "partial code search" do
      expect(search 'code: nav').to eq [@questions[0]]
    end

    it "question type search" do
      expect(search 'type: text').to eq [@questions[1]]
    end

    it "tag search" do
      expect(search 'tag: thriftstore').to eq [@questions[1]]
      # partial tag search should not work
      expect(search 'tag: thrifts').to eq []
    end

    it "empty search" do
      expect(search '').to eq @questions
    end
  end
end
