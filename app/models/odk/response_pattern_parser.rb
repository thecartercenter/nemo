# frozen_string_literal: true

module Odk
  # Parses $-style patterns involving responses, like default answer and default form instance name.
  # Returns output in xpath format using `concat`.
  class ResponsePatternParser < DynamicPatternParser
    include ERB::Util

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
      elsif calculated?
        # This token is going to end up inside an XML tag attribute so we need to encode it.
        # Except we don't want to encode single quotes because they are used heavily in calculate
        # expressions and it's not clear if they'd work encoded.
        html_escape(token).gsub("&#39;", "'")
      else
        "'#{html_escape(token)}'"
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
