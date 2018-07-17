# frozen_string_literal: true

module Odk
  # Parses $-style patterns involving responses, like default answer and default form instance name.
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
    def build_output(other_qing)
      if other_qing.has_options?
        xpath =
          if other_qing.multilevel?
            src_item.xpath_to(other_qing.subqings.first)
          else
            src_item.xpath_to(other_qing)
          end
        "jr:itext(#{xpath})"
      else
        src_item.xpath_to(other_qing)
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
