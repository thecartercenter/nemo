# frozen_string_literal: true

module Odk
  # Abstract parent class for classes that parse $-style patterns for ODK.
  class DynamicPatternParser
    # Basic regex for codes like $Question7
    CODE_REGEX = /[$][!]?[A-z]\w+/

    # Same as above but anchored to string start and end for checking individual tokens.
    ANCHORED_CODE_REGEX = Regexp.new("\\A#{CODE_REGEX.source}\\z")

    # Same as above but wrapped in parens for use in `split`.
    PAREN_CODE_REGEX = Regexp.new("(#{CODE_REGEX.source})")

    # Basic regex combined with quoted strings. Also for use in `split`.
    # We know that we don't have to deal with escaped quotes (much harder!) due to the way
    # XPath 1.0 is specified (you have to use html entities for quotes in strings).
    TOKEN_REGEX_WITH_STRINGS = Regexp.new(%{('[^']*'|"[^"]*"|#{CODE_REGEX.source})})

    def initialize(pattern, src_item:)
      self.pattern = pattern
      self.form = src_item.form
      self.src_item = Odk::DecoratorFactory.decorate(src_item)
      self.calculated = false
      self.codes_to_outputs = {}
      process_calc_wrapper
    end

    def to_odk
      tokens = pattern.split(token_regex).reject(&:empty?).map { |t| process_token(t) }.compact
      join_tokens(tokens)
    end

    protected

    attr_accessor :pattern, :src_item, :form, :calculated, :codes_to_outputs
    alias calculated? calculated

    def process_token(_token)
      raise NotImplementedError
    end

    def join_tokens(_tokens)
      raise NotImplementedError
    end

    # Given a decorated Questioning, determines what the actual target node
    # should be depending on if the qing is multilevel and has an external CSV.
    def target_qing_or_subqing(other_qing)
      return other_qing unless other_qing.multilevel?

      if other_qing.select_one_with_external_csv?
        other_qing.subqings.first
      else
        other_qing.subqings.last
      end
    end

    def itext_expr(xpath_to_node)
      # We need to use jr:itext to look up option names instead of their odk_code.
      # The coalesce is because ODK returns some ugly thing like [itext:] if it can't
      # find the requested itext resource. If the requested xml node is not filled in yet
      # we end up in this situation. Using 'BLANK' assumes there is an itext node in the form
      # with id 'BLANK' and an empty value.
      "jr:itext(coalesce(#{xpath_to_node},'BLANK'))"
    end

    private

    def token_is_code?(token)
      token.match?(ANCHORED_CODE_REGEX)
    end

    def process_calc_wrapper
      md = pattern.strip.match(/\Acalc\((.*)\)\z/i)
      return if md.nil?
      self.pattern = md[1]
      self.calculated = true
    end

    # Converts the given $-style code to the appropriate output fragment. Returns nil if code not valid.
    # Caches results in a hash.
    def process_code(code)
      return codes_to_outputs[code] if codes_to_outputs[code]
      unwrapped =
        if reserved_codes.key?(code)
          reserved_codes[code]
        elsif (qing = form.questioning_with_code(code[1..-1]))
          build_output(Odk::QingDecorator.decorate(qing))
        elsif calculated?
          # We don't want to return nil in calculated expressions because it might result in
          # invalid XPath. Better to return an empty string and hope that it doesn't break the form.
          "''"
        end
      codes_to_outputs[code] = calculated? ? "(#{unwrapped})" : unwrapped
    end

    # Returns the regular expression by which the input pattern should be split into tokens.
    def token_regex
      calculated? ? TOKEN_REGEX_WITH_STRINGS : PAREN_CODE_REGEX
    end
  end
end
