# frozen_string_literal: true

module Sms
  module Decoder
    # Parses a single rank/value pair as part of an incoming SMS message.
    class RankValuePair
      include ActiveModel::Model

      attr_accessor :rank, :value, :qing, :invalid_option_codes

      def initialize(*args)
        super
        self.invalid_option_codes = []
      end

      delegate :first_level_option_nodes, to: :option_set

      # Generates a hash of Answer attributes from the rank and value in the context of the given qing.
      # Raises an error if parsing failed.
      def parse
        raise ArgumentError, "qing must be set before parsing" if qing.nil?

        case qing.question.qtype.name
        when "integer", "counter"
          # for integer question, make sure the value looks like a number
          raise_parse_error("answer_not_integer") unless value =~ /\A\d+\z/

          # number must be in range
          val_f = value.to_f
          question = qing.question
          if question.maximum
            if question.maxstrictly && val_f >= question.maximum
              raise_parse_error("answer_too_large_strict", maximum: question.maximum)
            elsif val_f > question.maximum
              raise_parse_error("answer_too_large", maximum: question.maximum)
            end
          end

          if question.minimum &&
              (val_f < question.minimum || question.minstrictly && val_f == question.minimum)
            if question.minstrictly && val_f <= question.minimum
              raise_parse_error("answer_too_small_strict", minumum: question.minimum)
            elsif val_f < question.minimum
              raise_parse_error("answer_too_small", minumum: question.minimum)
            end
          end

          # add to response
          build_answer(qing, value: value)

        when "decimal"
          # for integer question, make sure the value looks like a number
          raise_parse_error("answer_not_decimal") unless value =~ /\A\d+([.,]\d+)?\z/

          # add to response
          build_answer(qing, value: value)

        when "select_one"
          if option_set.sms_formatting_as_text?
            option_node = option_set.descendants.by_canonical_name(value).first
            build_answer_from_option_node(qing, option_node)

          elsif option_set.sms_formatting_as_appendix?
            option_node = option_set.fetch_by_shortcode(value.downcase)
            build_answer_from_option_node(qing, option_node)

          else # Default formatting, just top level options and letters.
            raise_parse_error("answer_not_valid_option") unless value =~ /\A[a-z]+\z/i
            idx = letters_to_index(value.downcase)
            raise_parse_error("answer_not_valid_option") if idx > first_level_option_nodes.size
            build_answer(qing, option_node: first_level_option_nodes[idx - 1])
          end

        when "select_multiple"
          value.downcase!
          codes = split_select_multiple_value
          idxs = convert_select_multiple_codes_to_indices(codes)

          if invalid_option_codes.size > 1
            raise_parse_error("answer_not_valid_options_multi",
              value: value,
              invalid_options: invalid_option_codes.join(", "))
          elsif invalid_option_codes.size == 1
            raise_parse_error("answer_not_valid_option_multi",
              value: value,
              invalid_options: invalid_option_codes.first)
          end

          choices = idxs.uniq.map { |i| Choice.new(option_node: first_level_option_nodes[i - 1]) }
          build_answer(qing, choices: choices)

        when "text", "long_text"
          build_answer(qing, value: value)

        when "date"
          # error if too short (must be at least 8 chars)
          raise_parse_error("answer_not_date", value: value) if value.size < 8

          # try to parse date
          begin
            self.value = Date.parse(value)
          rescue ArgumentError
            raise_parse_error("answer_not_date", value: value)
          end

          # if we get to here, we're good, so add
          build_answer(qing, date_value: value)

        when "time"
          # error if too long or too short (must be 3 or 4 digits)
          digits = value.gsub(/[^\d]/, "")
          raise_parse_error("answer_not_time", value: value) if digits.size < 3 || digits.size > 4

          # try to parse time
          begin
            # add a colon before the last two digits (if needed)
            # and add UTC so timezone doesn't mess things up
            with_colon = value.gsub(/(\d{1,2})[.,]?(\d{2})/) do
              "#{Regexp.last_match(1)}:#{Regexp.last_match(2)}"
            end
            self.value = Time.zone.parse(with_colon + " UTC")
          rescue ArgumentError
            raise_parse_error("answer_not_time", value: value)
          end

          # if we get to here, we're good, so add
          build_answer(qing, time_value: value)

        when "datetime"
          # error if too long or too short (must be between 9 and 12 digits)
          digits = value.gsub(/[^\d]/, "")
          raise_parse_error("answer_not_datetime", value: value) if digits.size < 9 || digits.size > 12

          # try to parse datetime
          begin
            # if we have a string of 12 straight digits, leave it alone
            if value =~ /\A\d{12}\z/
              to_parse = value
            else
              # otherwise add a colon before the last two digits of the time (if needed) to help with parsing
              # also replace any .'s or ,'s or ;'s as they don't work so well
              to_parse = value.gsub(/(\d{1,2})[.,;]?(\d{2})[a-z\s]*$/) do
                "#{Regexp.last_match(1)}:#{Regexp.last_match(2)}"
              end
            end
            self.value = Time.zone.parse(to_parse)
          rescue ArgumentError
            raise_parse_error("answer_not_datetime", value: value)
          end

          # if we get to here, we're good, so add
          build_answer(qing, datetime_value: value)
        end
      end

      private

      def option_set
        @option_set ||= qing.option_set
      end

      def first_level_option_nodes
        @first_level_option_nodes ||= option_set.first_level_option_nodes
      end

      # converts a series of letters to the corresponding index, e.g. a => 1, b => 2, z => 26, aa => 27, etc.
      def letters_to_index(letters)
        sum = 0
        letters.split("").each_with_index do |letter, i|
          sum += (letter.ord - 96) * (26**(letters.size - i - 1))
        end
        sum
      end

      def split_select_multiple_value
        # if the option set has no commas, and has <= 26 options, assume it's a legacy submission
        # and split on spaces, otherwise split on commas
        if first_level_option_nodes.size <= 26 && value =~ /\A[A-Z]+\z/i
          raise_parse_error("answer_not_valid_long_option_multi") if value.length > 10
          value.split("")
        else
          value.split(/\s*,\s*/)
        end
      end

      def convert_select_multiple_codes_to_indices(codes)
        if option_set.sms_formatting_as_appendix?
          codes.map do |shortcode|
            option_node = option_set.fetch_by_shortcode(shortcode)
            if option_node.present?
              first_level_option_nodes.index(option_node) + 1
            else
              invalid_option_codes << shortcode
              -1
            end
          end
        else
          codes.map do |letter|
            if letter.match?(/\A[a-z]\z/i)
              idx = letters_to_index(letter)
              invalid_option_codes << letter if idx > first_level_option_nodes.size
              idx
            else
              invalid_option_codes << letter
              -1
            end
          end
        end
      end

      def build_answer_from_option_node(qing, option_node)
        raise_parse_error("answer_not_valid_option") unless option_node
        attribs_set = option_node.path.map { |node| {option_node: node} }
        build_answer(qing, attribs_set)
      end

      def build_answer(qing, attribs_set)
        Array.wrap(attribs_set).map do |attribs|
          # Include the full questioning object to avoid causing more queries later.
          attribs.merge(form_item: qing)
        end
      end

      def raise_parse_error(type, options = {})
        raise Sms::Decoder::ParseError.new(type, options)
      end
    end
  end
end
