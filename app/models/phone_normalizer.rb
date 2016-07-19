class PhoneNormalizer
  def self.is_shortcode?(phone)
    return nil if phone.blank?
    if phone =~ /[a-z]/i
      true
    else
      phone_digits = phone.gsub(/\D/, "")
      return false unless phone_digits.present?
      return true if phone_digits.size <= 6
      country_code = Phony.split(phone_digits).first
      phone_digits.size - country_code.size <= 6
    end
  end

  def self.normalize(phone)
    return unless phone.present?
    return phone if is_shortcode?(phone)
    return unless phone.gsub(/\D/, "").present?
    normalized = Phony.normalize(phone)
    return unless normalized.present?
    Phony.format(normalized, format: :+, spaces: "", local_spaces: "", parentheses: false)
  end
end
