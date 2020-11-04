# frozen_string_literal: true

# Class to help search for Users.
class UsersSearcher < Searcher
  # Returns the list of fields to be searched for this class.
  # Includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression.
  def search_qualifiers
    [
      Search::Qualifier.new(name: "name", col: "users.name", type: :text, default: true),
      Search::Qualifier.new(name: "login", col: "users.login", type: :text, default: true),
      Search::Qualifier.new(name: "email", col: "users.email", type: :text, default: true),
      Search::Qualifier.new(name: "phone", col: "users.phone", type: :text),
      Search::Qualifier.new(name: "group", col: "user_groups.name", type: :text, assoc: :user_groups),
      Search::Qualifier.new(name: "role", col: "assignments.role", type: :text, assoc: :assignments)
    ]
  end

  def apply
    return relation if query.blank?

    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    self.relation = relation.joins(search.associations).where(search.sql)

    # If scoped by mission, remove rows from other missions
    # This is used for the role qualifier, where the search should return only users whose role matches
    # in the current mission
    if search.uses_qualifier?("role") && scope && scope[:mission]
      relation.where("assignments.mission_id = ?", scope[:mission].id)
    else
      relation
    end
  end
end
