# Abstract parent class for classes that parse $-style patterns for ODK.
module Odk
  class DynamicPatternParser
    CODE_PATTERN = /([$][!]?[A-z]\w+)/

    def initialize(pattern, src_item:)
      @pattern = pattern
      @form = src_item.form
      @src_item = Odk::DecoratorFactory.decorate(src_item)
      @odk_mapping = {}
    end

    def to_odk
      # Map expression codes to relative paths
      code_mapping.each do |code, other_qing|
        other_qing = Odk::QingDecorator.decorate(other_qing)

        if reserved_codes.keys.include?(code)
          odk_mapping[code] = reserved_codes[code]
        else
          odk_mapping[code] = build_output(other_qing)
        end
      end

      tokens = pattern.split(CODE_PATTERN).reject(&:empty?)
      tokens.map! { |t| process_token(t) }
      tokens.compact!
      join_tokens(tokens)
    end

    protected

    attr_reader :pattern, :src_item, :form, :odk_mapping

    private

    def extract_codes
      @extracted_codes ||= pattern.scan(CODE_PATTERN).flatten
    end

    def code_mapping
      return @mapping if @mapping.present?
      @mapping = {}
      extract_codes.each do |code|
        questioning = form.questioning_with_code(code[1..-1])
        @mapping[code] = questioning if questioning.present?
        @mapping[code] = code if reserved_codes.keys.include?(code)
      end
      @mapping
    end
  end
end
