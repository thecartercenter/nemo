class PhoneNormalizer
  def self.is_shortcode?(phone)
    phone.present? && (phone =~ /[a-z]/i || phone.size <= 6)
  end

  def self.normalize(phone)
    if phone.blank?
      return nil
    elsif is_shortcode?(phone)
      return phone
    else
      return '+' + phone.gsub(/\D+/, '')
    end
  end
end
