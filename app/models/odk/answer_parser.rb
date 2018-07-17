# frozen_string_literal: true

module Odk
  # Fills answer value
  class AnswerParser
    attr_accessor :response, :files

    def initialize(response, files)
      @response = response
      @files = files
    end

    def populate_answer_value(answer, content, form_item)
      question_type = form_item.qtype.name
      return populate_multimedia_answer(answer, content, question_type) if form_item.qtype.multimedia?
      case question_type
      when "select_one"
        answer.option_id = option_id_for_option_node_code(content) # assume content has option node code ("on#{option_node.id}")
      when "select_multiple"
        unless content == "none"
          content.split(" ").each do |option_node_id|
            answer.choices.build(option_id: option_id_for_option_node_code(option_node_id))
          end
        end
      when "date", "datetime", "time"
        # Time answers arrive with timezone info (e.g. 18:30:00.000-04), but we treat a time question
        # as having no timezone, useful for things like 'what time of day does the doctor usually arrive'
        # as opposed to 'what exact date/time did the doctor last arrive'.
        # If the latter information is desired, a datetime question should be used.
        # Also, since Rails treats time data as always on 2000-01-01, using the timezone
        # information could lead to DST issues. So we discard the timezone information for time questions only
        # We also make sure elsewhere in the app to not tz-shift time answers when we display them.
        # (Rails by default keeps time columns as UTC and does not shift them to the system's timezone.)
        content = content.gsub(/(Z|[+\-]\d+(:\d+)?)$/, "") << " UTC" if answer.qtype.name == "time"
        answer.send("#{answer.qtype.name}_value=", Time.zone.parse(content))
      else
        answer.value = content
      end
      answer
    end

    def option_id_for_option_node_code(option_node_id)
      Odk::CodeMapper.instance.item_id_for_code(option_node_id, response.form)
    rescue SubmissionError
      nil
    end

    def add_media_to_existing_response
      candidate_answers = response.answers.select { |a| a.pending_file_name.present? }
      candidate_answers.each do |a|
        populate_multimedia_answer(a, a.pending_file_name, a.questioning.qtype_name)
      end
    end

    def populate_multimedia_answer(answer, pending_file_name, question_type)
      if files[pending_file_name].present?
        answer.pending_file_name = nil
        case question_type
        when "image", "annotated_image", "sketch", "signature"
          answer.media_object = Media::Image.create(item: files[pending_file_name])
        when "audio"
          answer.media_object = Media::Audio.create(item: files[pending_file_name])
        when "video"
          answer.media_object = Media::Video.create(item: files[pending_file_name])
        end
      else
        answer.value = nil
        answer.pending_file_name = pending_file_name
      end
      answer
    end
  end
end
