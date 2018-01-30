module Odk
  class ResponsePatternParser < DynamicPatternParser
    CODE_PATTERN = /([$][!]?[A-z]\w+)/

    def initialize(pattern, src_item:)
      @pattern = pattern
      @src_item = Odk::DecoratorFactory.decorate(src_item)
      @form = src_item.form
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



    def join_tokens(tokens)
      tokens.size > 1 ? "concat(#{tokens.join(',')})" : tokens.first
    end

    # Returns the output fragment for the given target questioning.
    def build_output(other_qing)
      if other_qing.has_options?
        if other_qing.multilevel?
          xpath = src_item.xpath_to(other_qing.subqings.first)
        else
          xpath = src_item.xpath_to(other_qing)
        end
        "jr:itext(#{xpath})"
      else
        src_item.xpath_to(other_qing)
      end
    end

    # Returns the desired output fragment for the given token from the input text.
    def process_token(token)
      odk_mapping.has_key?(token) ? odk_mapping[token] : "'#{token}'"
    end

    # Returns a hash of reserved $!XYZ style codes that have special meanings.
    # Keys are the code text, values are the desired output fragments.
    def reserved_codes
      return @reserved_codes if @reserved_codes
      @reserved_codes = {
        "$!RepeatNum" => "position(..)"
      }

      # We can't use repeat num if src_item is root because root or top level
      # because can't be in a repeat group.
      if src_item.depth < 2
        @reserved_codes["$!RepeatNum"] = nil
      end

      @reserved_codes
    end

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
