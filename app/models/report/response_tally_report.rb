class Report::ResponseTallyReport < Report::TallyReport
  include Report::Groupable

  protected

    def prep_query(rel)
      joins = []

      # add tally to select
      rel = rel.select("COUNT(responses.id) AS tally")

      # add filter
      rel = apply_filter(rel)

      # add groupings
      rel = apply_groupings(rel)
    end
end
