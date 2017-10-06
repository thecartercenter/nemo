class PhoneNormalizer
  def self.is_shortcode?(phone)
    return nil if phone.blank?
    if phone =~ /[a-z]/i
      true
    else
      phone_digits = phone.gsub(/\D/, "")
      return false unless phone_digits.present?
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
    return unless phone.present?
    return phone if is_shortcode?(phone)
    return unless phone.gsub(/\D/, "").present?
    begin
      normalized = Phony.normalize(phone)
    rescue Phony::NormalizationError
      # if something goes wrong, return + with the digits
      normalized = phone.gsub(/\D/, "")
      return "+#{normalized}"
    end
    return unless normalized.present?
    Phony.format(normalized, format: :+, spaces: "", local_spaces: "", parentheses: false)
  end
end
