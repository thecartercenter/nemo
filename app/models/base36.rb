module Base36
  def self.digits_needed(n)
    return 1 if n == 0
    Math::log(n, 36).floor + 1
  end

  def self.to_padded_base36(n, length: nil)
    return n.to_s(36) if (length == digits_needed(n)) || length.blank?
    raise "Length too short for number" if digits_needed(n) > length
    return (offset(length) + n).to_s(36) if digits_needed(offset(length) + n) == length
    n.to_s(36)
  end

  def self.offset(length)
    if length > 1
      36 ** (length - 1)
    else
      0
    end
  end
end
