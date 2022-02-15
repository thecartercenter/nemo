# frozen_string_literal: true

module ODK
  # Saves responses and is responsible for handling serialization and duplicate errors
  class ResponseSaver
    MAX_TRIES = 5

    def self.save_with_retries!(params)
      tries = 0
      loop do
        ActiveRecord::Base.transaction(isolation: :serializable) do
          return if ODK::ResponseParser.duplicate?(params[:submission_file], params[:user_id])
          sleep(5) if params[:test] && Rails.env.test?
          params[:response].save!(validate: false)
        end
        break
      rescue ActiveRecord::SerializationFailure => e
        return e if Rails.env.test?
        tries += 1
        raise e if tries >= MAX_TRIES
      end
    end
  end
end
