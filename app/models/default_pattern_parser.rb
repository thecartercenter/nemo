class DefaultPatternParser
  CODE_PATTERN = /([$][!]?[A-z]\w+)/
  RESERVED_CODES = {
    "$!RepeatNum" => "position(..)"
  }

  def initialize(pattern, src_item: src_item)
    @pattern = pattern
    @src_item = src_item
    @form = src_item.form
  end

  def to_odk
    odk_mapping = {}
    decorated_qing = Odk::DecoratorFactory.decorate(@src_item)

    # Map expression codes to relative paths
    code_mapping.each do |code, other_qing|
      if RESERVED_CODES.keys.include?(code)
        odk_mapping[code] = RESERVED_CODES[code]
      else
        odk_mapping[code] = decorated_qing.xpath_to(other_qing)
      end
    end

    expression_tokens = @pattern.split(CODE_PATTERN).reject(&:empty?)
    expression_tokens = expression_tokens.map do |token|
      odk_mapping[token].present? ? odk_mapping[token] : "'#{token}'"
    end

    "concat(#{expression_tokens.join(',')})"
  end

  private

  def extract_codes
    @extracted_codes ||= @pattern.scan(CODE_PATTERN).flatten
  end

  def code_mapping
    return @mapping if @mapping.present?
    @mapping = {}
    extract_codes.each do |code|
      questioning = @form.questioning_with_code(code[1..-1])
      @mapping[code] = questioning if questioning.present?
      @mapping[code] = code if RESERVED_CODES.keys.include?(code)
    end
    @mapping
  end
end
