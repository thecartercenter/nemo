# frozen_string_literal: true

class QuestionsSearcher
  def self.search_qualifiers
    [
      Search::Qualifier.new(name: "code", col: "questions.code", type: :text),
      Search::Qualifier.new(name: "title", col: "questions.name_translations", type: :translated,
                            default: true),
      Search::Qualifier.new(name: "type", col: "questions.qtype_name",
                            preprocessor: ->(s) { s.gsub(/[\-]/, "_") }),
      Search::Qualifier.new(name: "tag", col: "tags.name", assoc: :tags, type: :text)
    ]
  end

  # searches for questions
  # scope parameter is not used in Question search
  def self.do_search(relation, query, _scope, _options = {})
    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    # apply the needed associations
    relation = relation.joins(search.associations)

    # apply the conditions
    relation.where(search.sql)
  end
end
