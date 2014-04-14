# contains functions that are common to the old report style that needed to be refactored out of Report::Report
module Report::LegacyReport
  extend ActiveSupport::Concern

  included do
    attr_reader :header_set, :data, :totals, :query
  end

  # @param [current_ability] user ability to access Response object as defined by CanCan
  def run(current_ability=nil)
    # prep the relation and add a filter clause
    build_query = Response.unscoped.for_mission(mission)
    if current_ability
      build_query = build_query.accessible_by(current_ability)
    end
    @query = prep_query(build_query)

    # execute it the relation, returning rows, and create dbresult obj
    @db_result = Report::DbResult.new(@query.all)

    # extract headers
    @header_set = Report::HeaderSet.new(:row => get_row_header, :col => get_col_header)

    # extract data
    @data = Report::Data.new(blank_data_table(@db_result))
    @db_result.rows.each_with_index do |row, row_idx|
      extract_data_from_row(row, row_idx)
    end

    # clean out blank rows
    remove_blank_rows

    # compute totals if appropriate
    @data.compute_totals if can_total?
  end

  # legacy reports can all be exported to csv
  def exportable?
    true
  end

  protected
    # adds the given array of joins to the given relation by using the Join class
    def add_joins_to_relation(rel, joins)
      return rel.joins(Report::Join.list_to_sql(joins))
    end

    # builds a nested SQL IF statement of the form IF(a, x, IF(b, y, IF(c, z, ...)))
    def build_nested_if(exprs, conds, options = {})\
      unless options[:dont_optimize]
        # optimize by joining conditions for identical expressions
        # first build a hash
        expr_hash = {}
        exprs.each_with_index do |expr, i|
          expr_hash[expr] ||= []
          expr_hash[expr] << conds[i]
        end

        # rebuild condensed exprs and conds arrays
        exprs, conds = [], []
        expr_hash.each do |expr, cond_set|
          exprs << expr
          conds << cond_set.join(" OR ")
        end
      end

      if exprs.size == 1
        return exprs.first
      else
        rest = build_nested_if(exprs[1..-1], conds[1..-1], :dont_optimize => true)
        "IF(#{conds.first}, #{exprs.first}, #{rest})"
      end
    end

    # by default we don't have to worry about blank rows
    def remove_blank_rows
    end

    # checks if this report returned no data
    def empty?
      data.nil? ? true : data.rows.empty?
    end

    # builds a search object for the search string stored in the filter attrib
    # and applies it to the given relation, returning the result
    def apply_filter(rel)
      if filter.present?
        Response.do_search(rel, filter, :mission => mission)
      else
        rel
      end
    end
end
