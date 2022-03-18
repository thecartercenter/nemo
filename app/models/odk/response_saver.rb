# frozen_string_literal: true

module ODK
  # Saves responses and is responsible for handling serialization and duplicate errors
  class ResponseSaver
    MAX_TRIES = 10
    # For testing race conditions, stubbed in tests
    TEST_SLEEP_TIMER = 0

    def self.save_with_retries!(params)
      tries = 0
      loop do
        ActiveRecord::Base.transaction(isolation: :serializable) do
          if ODK::ResponseParser.duplicate?(params[:submission_file], params[:user_id])
            Sentry.capture_message("Ignored parallel duplicate")
            return
          end
          sleep(TEST_SLEEP_TIMER)
          params[:response].save!(validate: false)
        end
        break
      rescue ActiveRecord::SerializationFailure => e
        tries += 1
        raise e if tries >= MAX_TRIES
      end
    end
  end
end
