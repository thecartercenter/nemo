# Parses $-style patterns involving names, like group/question name and repeat instance name.
# Returns output in xml format using `output` tags.
module Odk
  class NamePatternParser < DynamicPatternParser

    def initialize(pattern, src_item:)
      # Name pattern output seems to require all absolute xpath.
      # Therefore we just calculate everything relative to the root group
      # instead of the specific src_item.
      super(pattern, src_item: src_item.root)
    end

    protected

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
  end
end