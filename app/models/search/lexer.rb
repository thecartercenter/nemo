# frozen_string_literal: true

class Search::Lexer
  attr_reader :tokens

  def initialize(str)
    @str = str.strip
    @tokens = []
  end

  # performs a lexical analysis on @str
  def lex
    # while there are characters left
    until @str.empty?
      token = nil
      match = nil
      chop = nil
      # try each token type
      Search::LexToken::KINDS.each do |defn|
        pattern = defn[:pattern]
        # look for a match at the start of the string for this token type
        if pattern.is_a?(String)
          if @str[0, pattern.size] == pattern
            match = pattern
            chop = pattern.size
          else
            match = nil
          end
        else
          if md = @str.match(/^#{pattern}/)
            match = md[defn[:sub_idx] || 0]
            chop = md[0].size
          else
            match = nil
          end
        end

        # if we found a match, create the LexToken and break
        next if match.nil?
        match = match.gsub('\\"', '"') if defn[:unescape_dbl_quotes]
        token = Search::LexToken.new(defn, match, @str)
        break
      end
      # if no token found, raise error
      if token.nil?
        raise Search::ParseError, I18n.t("search.unexpected", str: @str)
      # otherwise, add to token list and delete from the front
      else
        @tokens << token
        @str = @str[chop..-1]
        @str = @str.strip
      end
    end
    # add the end-of-text token to the end
    @tokens << Search::LexToken.new(name: :eot)
  end
end
