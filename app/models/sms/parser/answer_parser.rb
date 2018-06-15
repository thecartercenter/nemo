# frozen_string_literal: true

module Sms
  module Parser
    # Parses an incoming SMS message into an ordered list of rank/value pairs.
    class AnswerParser
      include Enumerable

      attr_reader :pairs
      delegate :each, to: :pairs

      def initialize(tokens)
        @pairs = []

        rank = nil
        value = ""

        tokens.each_with_index do |tok, index|
          match = handle_answer(tok, rank, value)
          if match
            rank, value = match
          elsif index.zero? # if this is the first answer token, raise error
            raise Sms::Parser::Error.new("first_answer_invalid", token: tok)
          else # otherwise, we add the token to the value variable and proceed
            value = value.blank? ? tok : value + " #{tok}"
          end
        end

        append_pair(rank, value)
      end

      private

      def handle_answer(token, rank, value)
        return unless (match = token.match(/\A(\d+)\.(.*)\z/))
        # Save the rank and values to temporary variables for a moment
        r = match[1].to_i
        v = match[2]
        append_pair(rank, value)
        [r, v]
      end

      def append_pair(rank, value)
        pairs << RankValuePair.new(rank, value) if value.present?
      end
    end
  end
end
