# frozen_string_literal: true

class PhoneNormalizer
  def self.is_shortcode?(phone)
    return nil if phone.blank?
    if /[a-z]/i.match?(phone)
      true
    else
      phone_digits = phone.gsub(/\D/, "")
      return false if phone_digits.blank?
      return true if phone_digits.size <= 6
      begin
        country_code = Phony.split(phone_digits).first
      rescue NoMethodError
        country_code = ""
      end
      phone_digits.size - country_code.size <= 6
    end
  end

  def self.normalize(phone)
    return if phone.blank?
    return phone if is_shortcode?(phone)
    return if phone.gsub(/\D/, "").blank?
    begin
      normalized = Phony.normalize(phone)
    rescue Phony::NormalizationError
      # if something goes wrong, return + with the digits
      normalized = phone.gsub(/\D/, "")
      return "+#{normalized}"
    end
    return if normalized.blank?
    Phony.format(normalized, format: :+, spaces: "", local_spaces: "", parentheses: false)
  end
end
