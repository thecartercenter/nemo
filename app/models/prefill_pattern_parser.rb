class PrefillPatternParser
  CODE_PATTERN = /([$][!]?[A-z]\w+)/
  RESERVED_CODES = {
    "$!RepeatNum" => "position(..)"
  }

  def initialize(qing)
    @qing = qing
    @form = @qing.form
    @prefill_pattern = @qing.prefill_pattern
  end

  def extract_codes
    @extracted_codes ||= @prefill_pattern.scan(CODE_PATTERN).flatten
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

  def to_odk
    odk_mapping = {}
    decorated_qing = Odk::DecoratorFactory.decorate(@qing)

    # map expression codes to relative paths
    code_mapping.each do |code, other_qing|
      if RESERVED_CODES.keys.include?(code)
        odk_mapping[code] = RESERVED_CODES[code]
      else
        odk_mapping[code] = decorated_qing.relative_xpath(other_qing)
      end
    end

    expression_tokens = @prefill_pattern.split(CODE_PATTERN).reject(&:empty?)

    expression_tokens = expression_tokens.map do |token|
      odk_mapping[token].present? ? odk_mapping[token] : "'#{token}'"
    end

    "concat(#{expression_tokens.join(',')})"
  end
end
