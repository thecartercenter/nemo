# frozen_string_literal: true

namespace :db do
  desc "Converts all occurrences of three letter lang codes (e.g. 'eng' to two letter equivalents)"
  task convert_to_two_letter_langs: :environment do
    # the only three languages in use to date are eng, ara, fra
    conv = {eng: :en, ara: :ar, fra: :fr}
    conv.each_pair do |three, two|
      Translation.update_all("language = '#{two}'", "language = '#{three}'")
      # Setting.update_all("outgoing_sms_language = '#{two}'", "outgoing_sms_language = '#{three}'")
    end

    Setting.all.each do |setting|
      setting.languages = setting.languages.split(",").map { |l| l.size == 3 ? conv[l.to_sym] : l }.join(",")
      setting.save(validate: false)
    end
  end
end
