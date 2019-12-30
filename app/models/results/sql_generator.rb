# frozen_string_literal: true

# Generates SQL that returns a nice view of the results data for use in an external app that
# via a DB connection.
class Results::SqlGenerator
  attr_accessor :mission

  # We accept a mission parameter here for scoping. Obviously, anybody able to run queries on the
  # DB has at least read access to all data, so this is not a security measure, just a convenience one.
  def initialize(mission)
    raise ArgumentError, "mission is required" unless mission&.persisted?
    self.mission = mission
  end

  # Generates SQL that produces one row per Answer and/or Choice for the given mission.
  # Assumes the language desired is English. Currently does not respect the locale (uses canonical_name).
  def generate
    Response
      .select("responses.id AS response_id")
      .select("responses.created_at AS submission_time")
      .select("responses.reviewed AS is_reviewed")
      .select("forms.name AS form_name")
      .select("questions.code AS question_code")
      .select("questions.canonical_name AS question_name")
      .select("questions.qtype_name AS question_type")
      .select("users.name AS submitter_name")
      .select("answers.id AS answer_id")
      .select("answers.new_rank AS rank")
      .select("answers.value AS value")
      .select("answers.datetime_value AS datetime_value")
      .select("answers.date_value AS date_value")
      .select("answers.time_value AS time_value")
      .select("answers.latitude AS latitude")
      .select("answers.longitude AS longitude")
      .select("COALESCE(ao.canonical_name, co.canonical_name) AS choice_name")
      .select("option_sets.name AS option_set")
      .joins(Results::Join.list_to_sql(:users, :forms, :answers, :questionings,
        :questions, :option_sets, :options, :choices))
      .where("responses.mission_id = ?", mission.id)
      .order("responses.created_at DESC")
      .to_sql
  end
end
