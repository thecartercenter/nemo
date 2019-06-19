# frozen_string_literal: true

# Methods pertaining to searching for objects in a controller action.
module Searchable
  extend ActiveSupport::Concern

  # Returns a Searcher. See apply_search for details.
  def build_searcher(relation)
    query = params[:search]
    searcher_class = query.blank? ? NoopSearcher : infer_searcher_class(relation)
    searcher_class.new(relation: relation, query: query, scope: {mission: current_mission})
  end

  # If params[:search] is present, runs a search using Searcher,
  # passing `relation` as the relation to which to apply the search,
  # and the `current_mission` as the search scope.
  #
  # Returns the new relation if search succeeds,
  # otherwise sets flash, flash[:search_error] = true, and returns `relation` unchanged.
  def apply_search(relation)
    searcher = build_searcher(relation)
    apply_searcher_safely(searcher)
  end

  # Applies the given Searcher, handling errors via flash.
  def apply_searcher_safely(searcher)
    searcher.apply
  rescue Search::ParseError => error
    flash.now[:error] = error.to_s
    flash.now[:search_error] = true
    searcher.relation
  end

  # Initializes variables used by the search filters.
  def init_filter_data(searcher = nil)
    @all_forms = Form.all.map { |item| {name: item.name, id: item.id} }.sort_by_key

    return unless searcher
    @form_ids = searcher.try(:form_ids)
    @advanced_text = searcher.try(:advanced_text)
  end

  private

  def infer_searcher_class(relation)
    klass = relation.klass
    return ResponsesSearcher if klass == Response
    return UsersSearcher if klass == User
    return QuestionsSearcher if klass == Question
    return Sms::MessagesSearcher if klass == Sms::Message
    raise "No Searcher class for #{relation.klass.name}"
  end
end
