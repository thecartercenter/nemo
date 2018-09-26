# frozen_string_literal: true

module Results
  # Quickly deletes a set of responses when given their IDs.
  class ResponseDeleter
    include Singleton
    
    def delete(ids)
      return if ids.empty?
      Media::Object.joins(:answer).where(answers: {response_id: ids}).delete_all
      Choice.joins(:answer).where(answers: {response_id: ids}).delete_all
      Answer.where(response_id: ids).delete_all
      Response.where(id: ids).delete_all
    end
  end
end
