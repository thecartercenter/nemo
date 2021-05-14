# frozen_string_literal: true

module ODK
  # Parses $-style patterns involving resulting in XPath expressions. Currently these can be in:
  # - Questioning > Default Answer
  # - Form > Default Response Name
  class ResponsePatternParser < DynamicPatternParser
    # Returns output in xpath format using `concat`, or in the case of a calculated field,
    # returns an arbitrary xpath expression.
    def to_odk
      super
    end

    protected

    def join_tokens(tokens)
      !calculated? && tokens.size > 1 ? "concat(#{tokens.join(',')})" : tokens.join
    end

    # Returns the output fragment for the given target questioning.
    def build_output(other_qing, option_value: false)
      if option_value
        xpath = src_item.xpath_to(target_qing_or_subqing(other_qing), prepend_current: true)
        option_set = other_qing.decorated_option_set
        option_value_expr(xpath, option_set.odk_code)
      else
        xpath = src_item.xpath_to(target_qing_or_subqing(other_qing))
        if other_qing.has_options?
          itext_expr(xpath)
        else
          xpath
        end
      end
    end

    # Returns the desired output fragment for the given token from the input text.
    def process_token(token)
      if token_is_code?(token)
        process_code(token)
      elsif calculated? || (src_item.is_a?(Questioning) && src_item.numeric?)
        # calculated expressions are passed on without modification.
        # Also, numeric source questions can't use the concat style so they either have to be calc
        # or have simple literals. If we're at this point, it's a simple literal, so don't quote it.
        token
      else
        # Replace ' with ’ because ' is used to wrap the tokens.
        token = token.tr("'", "’")
        "'#{token}'"
      end
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
      @reserved_codes["$!RepeatNum"] = nil if src_item.depth < 2

      @reserved_codes
    end
  end
end
