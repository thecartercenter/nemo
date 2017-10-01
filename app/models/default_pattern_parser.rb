class DefaultPatternParser
  CODE_PATTERN = /([$][!]?[A-z]\w+)/
  RESERVED_CODES = {
    "$!RepeatNum" => "position(..)"
  }

  def initialize(pattern, src_item:)
    @pattern = pattern
    @src_item = Odk::DecoratorFactory.decorate(src_item)
    @form = src_item.form
  end

  def to_odk
    odk_mapping = {}

    # Map expression codes to relative paths
    code_mapping.each do |code, other_qing|
      if reserved_codes.keys.include?(code)
        odk_mapping[code] = reserved_codes[code]
      else
        odk_mapping[code] = src_item.xpath_to(other_qing)
      end
    end

    tokens = pattern.split(CODE_PATTERN).reject(&:empty?)
    tokens = tokens.map do |token|
      odk_mapping.has_key?(token) ? odk_mapping[token] : "'#{token}'"
    end
    tokens.compact!

    tokens.size > 1 ? "concat(#{tokens.join(',')})" : tokens.first
  end

  private

  attr_reader :pattern, :src_item, :form

  def reserved_codes
    return @reserved_codes if @reserved_codes
    @reserved_codes = RESERVED_CODES.dup

    # We can't use repeat num if src_item is root because root or top level
    # because can't be in a repeat group.
    if src_item.depth < 2
      @reserved_codes["$!RepeatNum"] = nil
    end

    @reserved_codes
  end

  def extract_codes
    @extracted_codes ||= pattern.scan(CODE_PATTERN).flatten
  end

  def code_mapping
    return @mapping if @mapping.present?
    @mapping = {}
    extract_codes.each do |code|
      questioning = form.questioning_with_code(code[1..-1])
      @mapping[code] = questioning if questioning.present?
      @mapping[code] = code if RESERVED_CODES.keys.include?(code)
    end
    @mapping
  end
end
