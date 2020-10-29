# frozen_string_literal: true

ARGS = %i[start_time end_time mission_id timezone].freeze
task :recover_odk_xml, ARGS => :environment do |_t, args|
  unless ARGS.all? { |k| args.send(k).present? }
    argstr = ARGS.map { |a| "<#{a}>" }.join(",")
    abort("Usage: rake recover_odk_xml[#{argstr}]")
  end
  start_time = Time.zone.parse("#{args.start_time} UTC")
  end_time = Time.zone.parse("#{args.end_time} UTC")
  mission = Mission.find(args.mission_id)
  Time.zone = args.timezone
  puts "Finding responses from #{start_time} to #{end_time} from mission #{mission.name}."

  responses = Response.where(mission: mission)
    .where("created_at >= ?", start_time).where("created_at <= ?", end_time)
  puts "Found #{responses.count} responses."

  xml_path = Rails.root.join("tmp/uploads")

  responses.each do |response|
    puts "Response #{response.id}"

    stq = find_start_time_qing(response)
    unless stq
      puts "  WARNING! Could not find start time qing on form '#{response.form.name}', skipping"
      next
    end

    stq_ans = Answer.find_by(response: response, questioning: stq)
    unless stq_ans
      puts "  ERROR! Could not find start time answer, skipping"
      next
    end

    stq_ans_fmt = stq_ans.datetime_value.strftime("%Y-%m-%dT%H:%M:%S")
    puts "  Looking for time #{stq_ans_fmt} in #{xml_path}"
    matches = `grep -l "#{stq_ans_fmt}" #{xml_path}/*`.split("\n")
    if matches.empty?
      puts "  ERROR! No matches found for #{stq_ans_fmt}, response #{response.id}"
    elsif matches.size > 1
      puts "  ERROR! Multiple matches found for #{stq_ans_fmt}, response #{response.id}"
    else
      response.update_column(:odk_xml, File.read(matches[0]))
      puts "  Found match, updated DB!"
    end
  end
end

def find_start_time_qing(response)
  response.form.questionings.detect { |q| q.question.metadata_type == "formstart" }
end
