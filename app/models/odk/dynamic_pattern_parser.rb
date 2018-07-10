# Abstract parent class for classes that parse $-style patterns for ODK.
module Odk
  class DynamicPatternParser
    CODE_PATTERN = /([$][!]?[A-z]\w+)/

    def initialize(pattern, src_item:)
      @pattern = pattern
      @form = src_item.form
      @src_item = Odk::DecoratorFactory.decorate(src_item)
    end

    def to_odk
      tokens = pattern.split(CODE_PATTERN).reject(&:empty?).map { |t| process_token(t) }.compact
      join_tokens(tokens)
    end

    protected

    attr_reader :pattern, :src_item, :form

    private

    # Returns a map of $ABC style codes to the appropriate output fragment for each code.
    def code_to_output_map
      # Map expression codes to relative paths
      @code_to_output_map ||= extract_codes.map do |code|
        output =
          if reserved_codes.keys.include?(code)
            reserved_codes[code]
          elsif (qing = form.questioning_with_code(code[1..-1]))
            build_output(Odk::QingDecorator.decorate(qing))
          end
        [code, output]
      end.to_h
    end

    # Returns an array of $ABC style codes detected in the pattern.
    def extract_codes
      @extracted_codes ||= pattern.scan(CODE_PATTERN).flatten
    end
  end
end
