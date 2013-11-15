class Report::GroupedTallyReport < Report::TallyReport
  include Report::Groupable

  protected

    def prep_query(rel)
      joins = []

      # add tally to select
      rel = rel.select("COUNT(responses.id) AS tally")

      # add filter
      rel = filter.apply(rel) unless filter.nil?

      # add groupings
      rel = apply_groupings(rel)
    end
end
