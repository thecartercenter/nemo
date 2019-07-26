# frozen_string_literal: true

module Sms
  # Class to help search for Sms::Messages.
  class MessagesSearcher < Searcher
    # Returns the list of fields to be searched for this class.
    # Includes whether they should be included in a default, unqualified search
    # and whether they are searchable by a regular expression.
    def search_qualifiers
      # We pass explicit SQL here or else we end up with an INNER JOIN which excludes any message
      # with no associated user.
      user_assoc = "LEFT JOIN users ON users.id = sms_messages.user_id"

      [
        Search::Qualifier.new(name: "content", col: "sms_messages.body", type: :text, default: true),
        Search::Qualifier.new(name: "type", col: "sms_messages.type", type: :text),
        Search::Qualifier.new(name: "date", type: :date,
                              col: "CAST((sms_messages.created_at AT TIME ZONE 'UTC')
                                AT TIME ZONE '#{Time.zone.tzinfo.name}' AS DATE)"),
        Search::Qualifier.new(name: "datetime", col: "sms_messages.created_at", type: :date),
        Search::Qualifier.new(name: "username", col: "users.login", type: :text, assoc: user_assoc,
                              default: true),
        Search::Qualifier.new(name: "name", col: "users.name", type: :text, assoc: user_assoc,
                              default: true),
        Search::Qualifier.new(name: "number", col: %w[sms_messages.to sms_messages.from], type: :text,
                              default: true)
      ]
    end

    def apply
      return relation if query.blank?

      search = Search::Search.new(str: query, qualifiers: search_qualifiers)

      self.relation = relation.joins(search.associations)

      relation.where(search.sql)
    end
  end
end
