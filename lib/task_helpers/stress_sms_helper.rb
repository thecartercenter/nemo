class StressSmsHelper
  class << self
    attr_accessor :random_words
  end

  def self.create_incoming_sms(params)
    Sms::Incoming.create(
      from: params[:from],
      to: params[:to],
      body: params[:body],
      mission: params[:mission],
      sent_at: Time.zone.now, # Twilio doesn't supply this
      adapter_name: Sms::Adapters::TwilioTestStubAdapter.service_name)
  end

  def self.create_reply_sms(reply)
    Sms::Adapters::Factory.instance.create("TwilioTestStub").prepare_message_for_delivery(reply)
  end

  def self.signature_for_params(url, params, auth_token)
    validator = Twilio::Utils::RequestValidator.new auth_token
    validator.build_signature_for url, params
  end

  def self.read_words_file(file)
    self.random_words = File.foreach(file).map{ |line| line.chomp }
  end

  # This is for "Stress Test Form" on loadtest1
  # Some letter ranges are more than the ones accepted for
  # an answer to simulate some invalid messages
  #
  # 1 - (a..f)
  # 2 - text
  # 3 - (a..e)
  # 4 - (1..1000000)
  # 5 - text
  # 6 - (a..h)
  # 7 - (a..g)
  # 8 - (1..1000000)
  # 9 - (a..t)
  # 10 -text
  def self.build_message_for_form(form_code, correct_answers)
    responses = []

    if correct_answers
      responses << "1.#{random_letter('a','f')}"
    else
      responses << "1.#{random_letter('c','h')}"
    end
    responses << "2.#{random_text}"
    responses << "3.#{random_letter('a','e')}"
    responses << "4.#{rand(1000000)}"
    responses << "5.#{random_text}"
    responses << "6.#{random_letter('a','h')}"
    responses << "7.#{random_letter('a','g')}"
    responses << "8.#{rand(1000000)}"
    responses << "9.#{random_letter('a','t')}"
    responses << "10.#{random_text}"

    "#{form_code} #{responses.join(' ')}"
  end

  def self.random_letter(from, to)
    [*from..to].sample
  end

  def self.random_text
    if self.random_words.nil?
      "#{random_letter('a','z')}text#{random_letter('a','z')}"
    else
      text = []
      4.times{ text << self.random_words.sample }
      text.join(' ')
    end
  end

  def self.random_word
    self.random_words.sample
  end
end
