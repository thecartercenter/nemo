# frozen_string_literal: true

# Trick to let ResponseParser call `.read` on the xml_submission_file
MyFile = Struct.new(:read)

class FixPartiallyProcessedResponses < ActiveRecord::Migration[6.1]
  def up
    # Dates represent midnight UTC at the beginning of the given day.
    # See production-setup.md upgrade instructions for v12.26 for more details.
    start = Date.parse(ENV["NEMO_START_DATE"].presence || "2022-02-24")
    finish = Date.parse(ENV["NEMO_FINISH_DATE"].presence || "2022-03-25")

    remaining_responses = run_metrics(start, finish)
    repopulate(remaining_responses) if ENV["NEMO_REPOPULATE"].present? # Skipped by default.
  end

  def run_metrics(start, finish)
    puts "For date range #{start} to #{finish}:"

    total_responses = Response
      .where("created_at > ?", start).where("created_at < ?", finish)
    puts "TOTAL responses: #{total_responses.count}"

    normal_response_ids = ResponseNode
      .includes(:response)
      .joins("INNER JOIN answers parents ON answers.parent_id = parents.id AND parents.parent_id IS NULL")
      .where("responses.created_at > ?", start).where("responses.created_at < ?", finish)
      .pluck(:response_id).uniq
    puts "NORMAL responses: #{normal_response_ids.count}"

    blank_responses = total_responses
      .where.not(id: normal_response_ids)
    puts "BLANK responses: #{blank_responses.count}"
    puts "(blank responses represent an estimated fraction of the total number of responses affected; " \
      "additional responses may have only partially processed as well)"

    responses_without_odk_xml = Response
      .includes(:odk_xml_attachment)
      .joins("LEFT JOIN active_storage_attachments ON active_storage_attachments.record_id = responses.id")
      .where("responses.created_at > ?", start).where("responses.created_at < ?", finish)
      .reject { |r| r.odk_xml.attached? }
    puts "NON-XML responses: #{responses_without_odk_xml.count}"

    # Response gets touched when checking it out or adding cached_json,
    # but answers are more reliable.
    #
    # Note: this is a slow n+1 operation.
    edited_responses = total_responses
      .select do |r|
        r.root_node.descendants
          .where("answers.updated_at - answers.created_at > interval '10 seconds'").present?
      end
    puts "EDITED answers responses: #{edited_responses.count}"

    processed_responses = total_responses
      .where(temp_processed: true)
    puts "PROCESSED responses: #{processed_responses.count}"

    remaining_responses = total_responses
      .where(temp_processed: false).where.not(id: responses_without_odk_xml)
    puts "REMAINING responses: #{remaining_responses.count}"

    remaining_responses
  end

  def repopulate(remaining_responses)
    num_procs_available = ENV["NUM_PROCS"] ? ENV["NUM_PROCS"].to_i : Etc.nprocessors
    num_procs_to_use = (num_procs_available / 2.0).ceil
    puts "Reprocessing #{remaining_responses.count} using #{num_procs_to_use} CPUs..."

    total = remaining_responses.count
    Parallel.each_with_index(remaining_responses, in_processes: num_procs_to_use) do |response, index|
      puts "Repopulating #{response.shortcode} (#{index + 1} / #{total})..."

      # Get rid of the answer tree starting from the root AnswerGroup, then repopulate it.
      response.root_node&.destroy!
      ODK::ResponseParser.new(
        response: response,
        files: {xml_submission_file: MyFile.new(response.odk_xml.download)}
      ).populate_response

      response.update!(temp_processed: true)
    end
  end
end
