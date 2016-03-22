class PhoneNormalizer
  def self.is_shortcode?(phone)
    return nil if phone.blank?
    if phone =~ /[a-z]/i
      true
    else
      digits = phone.gsub(/\D/, "")
      !digits.empty? && digits.size <= 6
    end
  end

  def self.normalize(phone)
    phone = phone.try(:strip)
    if is_shortcode?(phone)
      phone
    else
      digits = phone.try(:gsub, /\D/, "")
      if digits.blank?
        nil
      else
        "+#{digits}"
      end
    end
  end
end
