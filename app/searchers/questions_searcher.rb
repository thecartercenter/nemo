# frozen_string_literal: true

# Class to help search for Questions.
class QuestionsSearcher < Searcher
  # Returns the list of fields to be searched for this class.
  # Includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression.
  def search_qualifiers
    [
      Search::Qualifier.new(name: "code", col: "questions.code", type: :text),
      Search::Qualifier.new(name: "title", col: "questions.name_translations", type: :translated,
                            default: true),
      Search::Qualifier.new(name: "type", col: "questions.qtype_name",
                            preprocessor: ->(s) { s.gsub(/[\-]/, "_") }),
      Search::Qualifier.new(name: "tag", col: "tags.name", assoc: :tags, type: :text)
    ]
  end

  def do_search
    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    # apply the needed associations
    self.relation = relation.joins(search.associations)

    # apply the conditions
    relation.where(search.sql)
  end
end
