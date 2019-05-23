# frozen_string_literal: true

class UsersSearcher
  def self.search_qualifiers
    [
      Search::Qualifier.new(name: "name", col: "users.name", type: :text, default: true),
      Search::Qualifier.new(name: "login", col: "users.login", type: :text, default: true),
      Search::Qualifier.new(name: "email", col: "users.email", type: :text, default: true),
      Search::Qualifier.new(name: "phone", col: "users.phone", type: :text),
      Search::Qualifier.new(name: "group", col: "user_groups.name", type: :text, assoc: :user_groups),
      Search::Qualifier.new(name: "role", col: "assignments.role", type: :text, assoc: :assignments)
    ]
  end

  # searches for users
  # relation - a User relation upon which to build the search query
  # query - the search query string (e.g. name:foo)
  def self.do_search(relation, query, scope, _options = {})
    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    # because assignments association is often added by the controller, only add if not already in relation
    search.associations.delete(:assignments) if relation.to_sql.match?(/JOIN "assignments" ON/)

    relation = relation.joins(search.associations).where(search.sql)

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
