# frozen_string_literal: true

module Odk
  # Parses $-style patterns involving names, like group/question name and repeat instance name.
  # Returns output in xml format using `output` tags.
  class NamePatternParser < DynamicPatternParser
    include ActionView::Helpers::TagHelper

    def initialize(pattern, src_item:)
      # Name pattern output seems to require all absolute xpath.
      # Therefore we just calculate everything relative to the root group
      # instead of the specific src_item.
      super(pattern, src_item: src_item.root)
    end

    # Returns XML containing <output> tags that interpolate the desired patterns.
    # In the case of a calculated field, returns a single <output> tag.
    def to_odk
      super
    end

    protected

    def join_tokens(tokens)
      calculated? ? output_tag(tokens.join) : tokens.join
    end

    # Returns the desired output fragment for the given token from the input text.
    def process_token(token)
      if token_is_code?(token)
        process_code(token)
      # If this token is only whitespace between two $ phrases in pattern
      elsif !calculated? && token =~ /\A\s+\z/
        # ODK ignores plain whitespace between output tags. This is a non-breaking space xml character.
        "&#160;"
      elsif calculated?
        token
      else
        token.tr("'", "’") # Replace ' with ’ because ' is used to wrap the tokens.
      end
    end

    # Returns the output fragment for the given target questioning.
    def build_output(other_qing)
      output =
        if other_qing.has_options?
          xpath = if other_qing.multilevel?
                    other_qing.subqings.first.absolute_xpath
                  else
                    other_qing.absolute_xpath
                  end
          # We need to use jr:itext to look up the option name instead of its odk_code
          # The coalesce is because ODK returns some ugly thing like [itext:] if it can't
          # find the requested itext resource. If the requested xml node not filled in yet
          # we end up in this situation. Using 'blank' assumes there is an itext node in the form
          # with id 'blank' and an empty value.
          "jr:itext(coalesce(#{xpath},'blank'))"
        else
          other_qing.absolute_xpath
        end

      # If this is a calculation pattern, we don't need to wrap in an output tag since
      # the whole expression will be so wrapped in join_tokens.
      calculated? ? output : output_tag(output)
    end

    # Returns a hash of reserved $!XYZ style codes that have special meanings.
    # Keys are the code text, values are the desired output fragments.
    def reserved_codes
      {}
    end

    private

    def output_tag(str)
      tag(:output, value: str)
    end
  end
end
