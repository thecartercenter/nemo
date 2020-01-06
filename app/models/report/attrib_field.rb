# frozen_string_literal: true

# models response attributes that are not answers to questions (user, date, etc.)
class Report::AttribField < Report::Field
  attr_accessor :name, :name_expr_params, :value_expr_params, :data_type, :groupable

  # builds one of each type of AttribField
  def self.all
    @@ATTRIBS.values.collect { |a| new(a[:name]) }
  end

  # builds a new object from the templates at the bottom of the file
  def initialize(attrib_name)
    unless @@ATTRIBS[attrib_name.to_sym]
      raise "attrib_name #{attrib_name} not found when creating AttribField object"
    end
    @@ATTRIBS[attrib_name.to_sym].each { |k, v| send("#{k}=", v) }
  end

  def name_expr(chunks, _prefer_value = false)
    @name_expr ||= Report::Expression.new(
      name_expr_params.merge(chunks: chunks.merge(current_timezone: Time.zone.tzinfo.name))
    )
  end

  def value_expr(chunks)
    @value_expr ||= Report::Expression.new(
      value_expr_params.merge(chunks: chunks.merge(current_timezone: Time.zone.tzinfo.name))
    )
  end

  def where_expr(_chunks)
    @where_expr ||= Report::Expression.new(sql_tplt: "", name: "where", clause: :where)
  end

  def sort_expr(chunks)
    @sort_expr ||= name_expr(chunks)
  end

  def joins
    @joins || []
  end

  def as_json(_options = {})
    {name: name, title: title}
  end

  def title
    I18n.t("attrib_fields.#{name}", default: name.to_s.tr("_", " ").ucwords)
  end

  private

  attr_writer :joins

  @@ATTRIBS = {
    response_id: {
      name: :response_id,
      name_expr_params: {sql_tplt: "responses.shortcode", name: "name", clause: :select},
      value_expr_params: {sql_tplt: "responses.shortcode", name: "value", clause: :select},
      data_type: :text
    },
    form: {
      name: :form,
      name_expr_params: {sql_tplt: "__TBL_PFX__forms.name", name: "name", clause: :select},
      value_expr_params: {sql_tplt: "__TBL_PFX__forms.name", name: "value", clause: :select},
      joins: [:forms],
      data_type: :text,
      groupable: true
    },
    submitter: {
      name: :submitter,
      name_expr_params: {sql_tplt: "__TBL_PFX__users.name", name: "name", clause: :select},
      value_expr_params: {sql_tplt: "__TBL_PFX__users.name", name: "value", clause: :select},
      joins: [:users],
      data_type: :text,
      groupable: true
    },
    submitter_username: {
      name: :submitter_username,
      name_expr_params: {sql_tplt: "__TBL_PFX__users.login", name: "name", clause: :select},
      value_expr_params: {sql_tplt: "__TBL_PFX__users.login", name: "value", clause: :select},
      joins: [:users],
      data_type: :text,
      groupable: true
    },
    source: {
      name: :source,
      name_expr_params: {sql_tplt: "responses.source", name: "name", clause: :select},
      value_expr_params: {sql_tplt: "responses.source", name: "value", clause: :select},
      data_type: :text,
      groupable: true
    },
    time_submitted: {
      name: :time_submitted,
      name_expr_params: {sql_tplt: "responses.created_at", name: "name", clause: :select},
      value_expr_params: {sql_tplt: "responses.created_at", name: "value", clause: :select},
      data_type: :datetime
    },
    date_submitted: {
      name: :date_submitted,
      name_expr_params: {
        sql_tplt:
          "CAST((responses.created_at AT TIME ZONE 'UTC') AT TIME ZONE '__CURRENT_TIMEZONE__' AS DATE)",
        name: "name",
        clause: :select
      },
      value_expr_params: {
        sql_tplt:
          "CAST((responses.created_at AT TIME ZONE 'UTC') AT TIME ZONE '__CURRENT_TIMEZONE__' AS DATE)",
        name: "value",
        clause: :select
      },
      data_type: :date,
      groupable: true
    },
    reviewed: {
      name: :reviewed,
      name_expr_params: {
        sql_tplt: "(CASE WHEN responses.reviewed THEN 'Yes' ELSE 'No' END)",
        name: "name",
        clause: :select
      },
      value_expr_params: {
        sql_tplt: "(CASE WHEN responses.reviewed THEN 1 ELSE 0 END)",
        name: "value",
        clause: :select
      },
      data_type: :text,
      groupable: true
    },
    reviewer: {
      name: :reviewer,
      name_expr_params: {sql_tplt: "__TBL_PFX__reviewers.name", name: "name", clause: :select},
      value_expr_params: {sql_tplt: "__TBL_PFX__reviewers.name", name: "value", clause: :select},
      joins: [:reviewers],
      data_type: :text,
      groupable: true
    }
  }
end
