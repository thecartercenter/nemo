# frozen_string_literal: true

module Base36
  def self.digits_needed(n)
    return 1 if n.zero?
    Math.log(n, 36).floor + 1
  end

  def self.to_padded_base36(n, length: nil)
    raise "Length too short for number" if digits_needed(n) > length
    (offset(length) + n).to_s(36)
  end

  def self.offset(length)
    if length > 1
      36**(length - 1)
    else
      0
    end
  end
end
