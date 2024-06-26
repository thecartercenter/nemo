# frozen_string_literal: true

require "rails_helper"

describe Results::CSV::AnswerProcessor do
  let(:buffer) { double }
  let(:processor) { described_class.new(buffer) }

  it "picks up value column" do
    expect(buffer).to receive(:write).with("Q1", "10")
    processor.process({"question_code" => "Q1", "value" => "10"})
  end

  it "picks up date_value column" do
    expect(buffer).to receive(:write).with("Q1", "2018-01-13")
    processor.process({"question_code" => "Q1", "date_value" => "2018-01-13"})
  end

  it "picks up time_value column" do
    expect(buffer).to receive(:write).with("Q1", "12:34:56")
    processor.process({"question_code" => "Q1", "time_value" => "12:34:56"})
  end

  it "picks up datetime_value column" do
    expect(buffer).to receive(:write).with("Q1", "2018-01-13 12:34:56")
    processor.process({"question_code" => "Q1", "datetime_value" => "2018-01-13 12:34:56"})
  end

  it "ignores value if lat/lng/alt/acc given" do
    expect(buffer).to receive(:write).with("Q1:Latitude", "12.34")
    expect(buffer).to receive(:write).with("Q1:Longitude", "56.78")
    expect(buffer).to receive(:write).with("Q1:Altitude", "145.7")
    expect(buffer).to receive(:write).with("Q1:Accuracy", "9.1")
    processor.process({
      "question_code" => "Q1",
      "value" => "12.34 56.78 145.7 9.1",
      "latitude" => "12.34",
      "longitude" => "56.78",
      "altitude" => "145.7",
      "accuracy" => "9.1"
    })
  end

  it "handles select_one data" do
    expect(buffer).to receive(:write).with("Q1", "Cat")
    processor.process({"question_code" => "Q1", "option_level_name" => nil, "answer_option_name" => "Cat"})
  end

  it "handles select_one data with numeric value" do
    expect(buffer).to receive(:write).with("Q1", 123)
    processor.process({
      "question_code" => "Q1",
      "option_level_name" => nil,
      "answer_option_name" => "Cat",
      "answer_option_value" => 123
    })
  end

  it "handles multilevel select_one data" do
    expect(buffer).to receive(:write).with("Q1:Kingdom", "Animal")
    expect(buffer).to receive(:write).with("Q1:Species", "Cat")
    processor.process({
      "question_code" => "Q1",
      "option_level_name" => "Kingdom",
      "answer_option_name" => "Animal"
    })
    processor.process({
      "question_code" => "Q1",
      "option_level_name" => "Species",
      "answer_option_name" => "Cat"
    })
  end

  it "handles select_one with geo data" do
    # Latter location writes will supersede earlier ones.
    expect(buffer).to receive(:write).with("Q1:Region", "Topeka").ordered
    expect(buffer).to receive(:write).with("Q1:Latitude", "12.34").ordered
    expect(buffer).to receive(:write).with("Q1:Longitude", "56.78").ordered
    expect(buffer).to receive(:write).with("Q1:Altitude", "145.7").ordered
    expect(buffer).to receive(:write).with("Q1:Landmark", "The old watering hole").ordered
    expect(buffer).to receive(:write).with("Q1:Latitude", "1.23").ordered
    expect(buffer).to receive(:write).with("Q1:Longitude", "4.56").ordered
    expect(buffer).to receive(:write).with("Q1:Altitude", "78.9").ordered
    processor.process({
      "question_code" => "Q1",
      "value" => "12.34 56.78 145.7",
      "latitude" => "12.34",
      "longitude" => "56.78",
      "altitude" => "145.7",
      "option_level_name" => "Region",
      "answer_option_name" => "Topeka"
    })
    processor.process({
      "question_code" => "Q1",
      "value" => "1.23 4.56 78.9",
      "latitude" => "1.23",
      "longitude" => "4.56",
      "altitude" => "78.9",
      "option_level_name" => "Landmark",
      "answer_option_name" => "The old watering hole"
    })
  end

  it "handles select_multiple data" do
    expect(buffer).to receive(:write).with("Q1", "Mars", append: true)
    expect(buffer).to receive(:write).with("Q1", "Snickers", append: true)
    processor.process({
      "question_code" => "Q1",
      "option_level_name" => nil,
      "choice_option_name" => "Mars"
    })
    processor.process({
      "question_code" => "Q1",
      "option_level_name" => nil,
      "choice_option_name" => "Snickers"
    })
  end

  it "handles select_multiple data with numeric data" do
    expect(buffer).to receive(:write).with("Q1", 123, append: true)
    processor.process({
      "question_code" => "Q1",
      "option_level_name" => nil,
      "choice_option_name" => "Cat",
      "choice_option_value" => 123
    })
  end

  context "long_text_behavior" do
    before do
      stub_const(Results::CSV::AnswerProcessor, "MAX_NEWLINES", 1)
      stub_const(Results::CSV::AnswerProcessor, "MAX_CHARACTERS", 12)
    end

    it "excludes long text" do
      expect(buffer).to receive(:write).with("Q1", "")
      processor.process(
        {"question_code" => "Q1", "value" => +"12345", "qtype_name" => "long_text"},
        long_text_behavior: "exclude"
      )
    end

    it "doesn't exclude regular text" do
      expect(buffer).to receive(:write).with("Q1", "12345")
      processor.process(
        {"question_code" => "Q1", "value" => +"12345", "qtype_name" => "text"},
        long_text_behavior: "exclude"
      )
    end

    it "truncates after max characters" do
      expect(buffer).to receive(:write).with("Q1", "1234567890ab")
      processor.process(
        {"question_code" => "Q1", "value" => +"1234567890abcde", "qtype_name" => "long_text"},
        long_text_behavior: "truncate"
      )
    end

    it "truncates after max newlines (below max)" do
      expect(buffer).to receive(:write).with("Q1", "12\r\n345")
      processor.process(
        {"question_code" => "Q1", "value" => +"12\r345", "qtype_name" => "long_text"},
        long_text_behavior: "truncate"
      )
    end

    it "truncates after max newlines (above max)" do
      expect(buffer).to receive(:write).with("Q1", "12\r\n34")
      processor.process(
        {"question_code" => "Q1", "value" => +"12\n34\n5", "qtype_name" => "long_text"},
        long_text_behavior: "truncate"
      )
    end

    it "counts each CRLF as a single line" do
      expect(buffer).to receive(:write).with("Q1", "\r\nfoo")
      processor.process(
        {"question_code" => "Q1", "value" => +"\r\nfoo\r\nbar\r\n", "qtype_name" => "long_text"},
        long_text_behavior: "truncate"
      )
    end

    it "handles a dangling CR at end of truncated string" do
      expect(buffer).to receive(:write).with("Q1", "1234567890a")
      processor.process(
        {"question_code" => "Q1", "value" => +"1234567890a\r\nb", "qtype_name" => "long_text"},
        long_text_behavior: "truncate"
      )
    end
  end
end
