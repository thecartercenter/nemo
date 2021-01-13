# frozen_string_literal: true

module ODK
  # Fills answer value
  class AnswerParser
    attr_accessor :response, :files

    def initialize(response, files)
      @response = response
      @files = files
    end

    def populate_answer_value(answer, content, form_item)
      qtype = form_item.qtype
      return populate_multimedia_answer(answer, content, qtype.name) if qtype.multimedia?

      case qtype.name
      when "select_one"
        # assume content has option node code ("on#{option_node.id}")
        answer.option_node_id = safe_item_id_for_code(content)
      when "select_multiple"
        unless content == "none"
          content.split(" ").each do |code|
            answer.choices.build(mission_id: response.mission_id, option_node_id: safe_item_id_for_code(code))
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

    # Get the item ID, unless it's nil (normally that would raise an error).
    def safe_item_id_for_code(code)
      code.present? ? CodeMapper.instance.item_id_for_code(code) : nil
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
        answer.media_object = create_media_object(pending_file_name, question_type)
      else
        answer.value = nil
        answer.pending_file_name = pending_file_name
      end
      answer
    end

    # Creates a media object for the given file and question type. If the object doesn't pass
    # validation, discards it and returns nil.
    def create_media_object(pending_file_name, question_type)
      klass = media_class(question_type)
      raise "media class not found for question type #{question_type}" unless klass

      begin
        file = files[pending_file_name]
        object = klass.new
        object.item.attach(io: file, filename: File.basename(file))
        object.save!
        object
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.info("Media object failed validation on ODK upload, skipping (message: '#{e}', "\
          "filename: '#{pending_file_name}')")
        nil
      end
    end

    # May return nil if no match.
    def media_class(qtype_name)
      case qtype_name
      when "image", "annotated_image", "sketch", "signature" then Media::Image
      when "audio" then Media::Audio
      when "video" then Media::Video
      end
    end
  end
end
