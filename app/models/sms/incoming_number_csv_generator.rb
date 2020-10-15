# frozen_string_literal: true

module Sms
  # Exports list of incoming SMS numbers to simple CSV.
  class IncomingNumberCSVGenerator
    include ActiveModel::Model

    attr_accessor :numbers

    def to_csv
      UserFacingCSV.generate do |csv|
        csv << %w[id phone_number].map { |k| I18n.t("sms_form.incoming_numbers.#{k}") }
        numbers.each_with_index do |number, i|
          csv << [i + 1, number]
        end
      end
    end
  end
end
