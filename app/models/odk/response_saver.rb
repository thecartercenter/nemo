# frozen_string_literal: true

module ODK
  # Saves responses and is responsible for handling serialization and duplicate errors
  class ResponseSaver
    # The more tries, the more likely it is to eventually succeed
    MAX_TRIES = 12

    def self.save_with_retries!(params)
      tries = 0
      loop do
        ActiveRecord::Base.transaction(isolation: :serializable) do
          if ODK::ResponseParser.duplicate?(params[:submission_file], params[:user_id])
            Sentry.capture_message("Ignored parallel duplicate")
            return
          end
          params[:response].save!(validate: false)
        end
        break
      rescue ActiveRecord::SerializationFailure => e
        tries += 1

        # Note for future: Do we still need to destroy the blank response in this case?
        # See notes related to https://redmine.sassafras.coop/issues/12142.
        raise e if tries >= MAX_TRIES

        # Delay a short, random number of milliseconds
        # to allow different requests to try in various orders.
        sleep(rand(1..100) / 1000.0)
      end
    end
  end
end
