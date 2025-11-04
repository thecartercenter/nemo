# frozen_string_literal: true

namespace :rank do
  # be rails rank:audit
  desc "Audits form rank data globally."
  task :audit, [:this_is_required_to_load_sql_for_some_reason] => :environment do
    puts rank_gaps.any? ? "Uh oh, there are rank gaps before each of these FormItems:" : "Good, there are no rank gaps."
    rank_gaps.map do |row|
      id = row["id"]
      form_item = FormItem.includes(:mission, :form).find(id)
      puts "#{form_item.code}\tRank #{form_item.rank}\tMission #{form_item.mission.name}\tForm #{form_item.form.name}"
    end
    puts

    puts duplicate_ranks.any? ? "Uh oh, there are duplicate ranks for each of these FormItems:" : "Good, there are no duplicate ranks."
    duplicate_ranks.map do |row|
      ancestry = row["ancestry"]
      form_item = FormItem.includes(:mission, :form).find_by(ancestry: ancestry)
      puts "#{form_item.code}\tRank #{form_item.rank}\tMission #{form_item.mission.name}\tForm #{form_item.form.name}"
    end
    puts
  end

  # be rails rank:redo[FORM_ID]
  desc "Re-ranks all form items in a given form."
  task :redo, [:form_id] => :environment do |_, args|
    form_id = args[:form_id]
    form = Form.find_by(id: form_id)
    unless form
      puts "Form ID not found: '#{form_id}'."
      next
    end

    puts "Re-ranking #{form.descendants.count} descendants..."
    ranks = {}
    FormItem.where(form: form).ordered_by_ancestry_and(:rank).each do |form_item|
      next if form_item.depth.zero? # This is the root node.
      ranks[form_item.ancestry] ||= 0
      ranks[form_item.ancestry] += 1
      puts "#{form_item.full_dotted_rank}: #{form_item.rank} => #{ranks[form_item.ancestry]}"
      form_item.update!(rank: ranks[form_item.ancestry])
    end
  end
end

def rank_gaps
  SqlRunner.instance.run("
      SELECT id FROM form_items fi1
      WHERE fi1.rank > 1 AND NOT EXISTS (
        SELECT id FROM form_items fi2
        WHERE fi2.ancestry = fi1.ancestry AND fi2.rank = fi1.rank - 1)
    ")
end

def duplicate_ranks
  SqlRunner.instance.run("
      SELECT ancestry, rank
      FROM form_items
      WHERE ancestry is NOT NULL AND ancestry != ''
      GROUP BY ancestry, rank
      HAVING COUNT(id) > 1
    ")
end
