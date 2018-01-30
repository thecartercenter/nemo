module Odk
  class NamePatternParser < DynamicPatternParser
    CODE_PATTERN = /([$][!]?[A-z]\w+)/

    def initialize(form, pattern)
      @form = form
      @pattern = pattern
      @src_item = Odk::QingGroupDecorator.decorate(form.root_group)
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
      tokens.size > 1 ? tokens.join : tokens.first
    end

    # Returns the output fragment for the given target questioning.
    def build_output(other_qing)
      if other_qing.has_options?
        if other_qing.multilevel?
          xpath = other_qing.subqings.first.absolute_xpath
        else
          xpath = other_qing.absolute_xpath
        end
        # We need to use jr:itext to look up the option name instead of its odk_code
        # The coalesce is because ODK returns some ugly thing like [itext:] if it can't
        # find the requested itext resource. If the requested xml node not filled in yet
        # we end up in this situation. Using 'blank' assumes there is an itext node in the form
        # with id 'blank' and an empty value.
        %Q{<output value="jr:itext(coalesce(#{xpath},'blank'))"/>}
      else
        xpath = other_qing.absolute_xpath
        %Q{<output value="#{xpath}"/>}
      end
    end

    # Returns the desired output fragment for the given token from the input text.
    def process_token(token)
      if odk_mapping.has_key?(token)
        odk_mapping[token]
      elsif token =~ /\A\s+\z/ #this token is only whitespace between two $ phrases in pattern
        "&#160;" #odk ignores plain whitespace between output tags. This is a non-breaking space xml character
      else
        token
      end
    end

    # Returns a hash of reserved $!XYZ style codes that have special meanings.
    # Keys are the code text, values are the desired output fragments.
    def reserved_codes
      {}
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