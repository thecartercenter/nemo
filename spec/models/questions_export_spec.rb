# frozen_string_literal: true

require "rails_helper"

describe Questions::Export do
  let(:mission) { create(:mission) }
  let(:q1) { create(:question, mission_id: mission.id) }
  let!(:yesno) { create(:option_set, name: "yesno", mission_id: mission.id) }

  let!(:q1) do
    create(:question,
      name_en: "How many cheeses?",
      name_fr: "Combien de fromages?",
      name_ht: "Fromage",
      hint_en: "cheesey",
      hint_fr: "fromagey",
      hint_ht: "fr",
      code: "Cheese",
      mission_id: mission.id)
  end

  let!(:q2) do
    create(:question,
      name_en: "Your job?",
      name_fr: "Votre metier?",
      qtype_name: "text",
      mission_id: mission.id)
  end

  let!(:q3) do
    create(:question,
      name_en: "Yea or nay?",
      hint: nil,
      qtype_name: "select_one",
      option_set: yesno,
      mission_id: mission.id)
  end

  context "export with some translations and some not", :reset_factory_sequences do
    before do
      mission.setting.preferred_locales_str = "en,fr,ht"
      mission.save
    end

    it "should be able to export" do
      exporter = Questions::Export.new(Question.all, mission.setting.preferred_locales)
      csv = exporter.to_csv
      expect(csv).to eq(
        "Code,QType,Option Set Name,Title[en],Hint[en],Title[fr],Hint[fr],Title[ht],Hint[ht]\n"\
        "Cheese,integer,\"\",How many cheeses?,cheesey,Combien de fromages?,fromagey,Fromage,fr\n"\
        "TextQ1,text,\"\",Your job?,Question Hint 2,Votre metier?,,,\n"\
        "SelectOneQ2,select_one,yesno,Yea or nay?,\"\",,\"\",,\"\"\n"
      )
    end
  end
end
