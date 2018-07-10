# Parses $-style patterns involving responses, like default answer and default form instance name.
# Returns output in xpath format using `concat`.
module Odk
  class ResponsePatternParser < DynamicPatternParser

    protected

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
      code_to_output_map.has_key?(token) ? code_to_output_map[token] : "'#{token}'"
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
  end
end
