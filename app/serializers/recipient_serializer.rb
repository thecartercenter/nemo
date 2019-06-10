# frozen_string_literal: true

# Serializes possible recipients for a Broadcast.
class RecipientSerializer < ApplicationSerializer
  attributes :id, :text

  def text
    object.name
  end
end
