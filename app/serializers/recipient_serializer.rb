# frozen_string_literal: true

# Serializes possible recipients for a Broadcast.
class RecipientSerializer < ApplicationSerializer
  fields :id
  field :name, name: :text
end
