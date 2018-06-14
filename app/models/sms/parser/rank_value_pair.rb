# frozen_string_literal: true

module Sms
  module Parser
    # Parses a single rank/value pair as part of an incoming SMS message.
    class RankValuePair < Struct.new(:rank, :value)
      # Generates an Answer object from the rank and value in the context of the given qing.
      # Raises an error if parsing failed.
      def parse(qing)
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

          if question.minimum && (val_f < question.minimum || question.minstrictly && val_f == question.minimum)
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
          raise_parse_error("answer_not_decimal") unless value =~ /\A[\d]+([\.,][\d]+)?\z/

          # add to response
          build_answer(qing, value: value)

        when "select_one"
          if qing.sms_formatting_as_text?
            option = qing.option_set.all_options.by_canonical_name(value).first
            raise_parse_error("answer_not_valid_option") unless option
            attribs_set = qing.option_set.path_to_option(option).map { |o| {option: o} }
            build_answer(qing, attribs_set, multilevel: qing.multilevel?)

          elsif qing.sms_formatting_as_appendix?
            option = qing.option_set.fetch_by_shortcode(value.downcase).try(:option)
            raise_parse_error("answer_not_valid_option") unless option
            attribs_set = qing.option_set.path_to_option(option).map { |o| {option: o} }
            build_answer(qing, attribs_set, multilevel: qing.multilevel?)

          else
            # make sure the value is a letter(s)
            raise_parse_error("answer_not_valid_option") unless value =~ /\A[a-z]+\z/i

            # convert to number (1-based)
            idx = letters_to_index(value.downcase)

            # make sure it makes sense for the option set
            raise_parse_error("answer_not_valid_option") if idx > qing.question.options.size

            # if we get to here, we're good, so add
            build_answer(qing, option: qing.question.options[idx - 1])
          end

        when "select_multiple"
          # case insensitive
          value.downcase!

          # hopefully this stays empty!
          invalid = []

          # split options

          # if the option set has no commas, and has <= 26 options, assume it's a legacy submission
          # and split on spaces, otherwise split on commas
          if qing.option_set.descendants.count <= 26 && value =~ /\A[A-Z]+\z/i
            raise_parse_error("answer_not_valid_long_option_multi") if value.length > 10
            split_options = value.split("")
          else
            split_options = value.split(/\s*,\s*/)
          end

          idxs = if qing.option_set.sms_formatting == "appendix"
                   # fetch each option by shortcode
                   split_options.map do |l|
                     option = qing.option_set.fetch_by_shortcode(l).try(:option)
                     # make sure an option was found
                     if option.present?
                       # convert to an index
                       option_to_index(option, qing)
                     # otherwise add to invalid and return nonsense index
                     else
                       invalid << l unless option.present?
                       -1
                     end
                   end
                 else
                   # deal with each option, accumulating a list of indices
                   split_options.map do |l|
                     # make sure it's a letter
                     if l =~ /\A[a-z]\z/i

                       # convert to an index
                       idx = letters_to_index(l)

                       # make sure this index makes sense for the option set
                       invalid << l if idx > qing.question.options.size

                       idx

                     # otherwise add to invalid and return a nonsense index
                     else
                       invalid << l
                       -1
                     end
                   end
                 end

          # raise appropriate error if we found invalid answer(s)
          if invalid.size > 1
            raise_parse_error("answer_not_valid_options_multi",
              value: value,
              invalid_options: invalid.join(", "))
          elsif invalid.size == 1
            raise_parse_error("answer_not_valid_option_multi",
              value: value,
              invalid_options: invalid.first)
          end

          # if we get to here, we're good, so add
          build_answer(qing, choices: idxs.map { |i| Choice.new(option: qing.question.options[i - 1]) })

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
            # add a colon before the last two digits (if needed) and add UTC so timezone doesn't mess things up
            with_colon = value.gsub(/(\d{1,2})[\.,]?(\d{2})/) do
              "#{$1}:#{$2}"
            end
            self.value = Time.parse(with_colon + " UTC")
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
              to_parse = value.gsub(/(\d{1,2})[\.,;]?(\d{2})[a-z\s]*$/) do
                "#{$1}:#{$2}"
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

      # converts a series of letters to the corresponding index, e.g. a => 1, b => 2, z => 26, aa => 27, etc.
      def letters_to_index(letters)
        sum = 0
        letters.split("").each_with_index do |letter, i|
          sum += (letter.ord - 96) * (26**(letters.size - i - 1))
        end
        sum
      end

      def option_to_index(option, qing)
        # add one because of how letter indexes are counted
        qing.question.options.index { |o| o.id == option.id } + 1
      end

      def build_answer(qing, attribs_set, options = {})
        Array.wrap(attribs_set).each_with_index.map do |attribs, idx|
          attribs.merge(
            rank: options[:multilevel] ? idx + 1 : 1,
            questioning_id: qing.id
          )
        end
      end

      def raise_parse_error(type, options = {})
        raise Sms::Parser::Error.new(type, options)
      end
    end
  end
end
