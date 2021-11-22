# frozen_string_literal: true

require "rails_helper"

describe Forms::Export do
  let(:headers) do
    "Level,Type,Code,Prompt,Required?,Repeatable?,DisplayLogic,Default,Hidden\n"
  end

  context "simple form" do
    let(:simpleform) { create(:form, question_types: %w[text integer text]) }

    it "should produce the correct csv" do
      exporter = Forms::Export.new(simpleform)
      q1 = simpleform.questionings[0]
      q2 = simpleform.questionings[1]
      q3 = simpleform.questionings[2]
      expect(exporter.to_csv).to eq(
        "#{headers}"\
        "1,text,#{q1.code},#{q1.name},false,false,always,,false\n"\
        "2,integer,#{q2.code},#{q2.name},false,false,always,,false\n"\
        "3,text,#{q3.code},#{q3.name},false,false,always,,false\n"
      )
    end
  end

  context "repeat group form" do
    let(:repeatgroupform) do
      create(
        :form,
        question_types: ["text", "integer", {repeating: {items: %w[text text]}}]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(repeatgroupform)
      q1 = repeatgroupform.questionings[0]
      q2 = repeatgroupform.questionings[1]
      q31 = repeatgroupform.questionings[2]
      q32 = repeatgroupform.questionings[3]
      expect(exporter.to_csv).to eq(
        "#{headers}"\
        "1,text,#{q1.code},#{q1.name},false,false,always,,false\n"\
        "2,integer,#{q2.code},#{q2.name},false,false,always,,false\n"\
        "3.1,text,#{q31.code},#{q31.name},false,true,always,,false\n"\
        "3.2,text,#{q32.code},#{q32.name},false,true,always,,false\n"\
      )
    end
  end

  context "skip logic form" do
    let(:skiplogicform) do
      create(
        :form,
        
      )
    end
  end
end
