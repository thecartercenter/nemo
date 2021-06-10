# frozen_string_literal: true

class RenameMediaFilesToIncludeGroup < ActiveRecord::Migration[6.1]
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "Media::Object")
    total = attachments.count
    puts "Total attachments: #{attachments.count}"
    attachments.includes(record: {answer: :response}).each_with_index do |attachment, index|
      media_object = attachment.record
      if media_object.nil?
        puts "Skipping nil media for #{attachment.id}"
        next
      end
      generate_media_object_filename(media_object, index, total)
    end
  end

  def generate_media_object_filename(media_object, index, total)
    item = media_object.item
    if item.record.answer_id.nil?
      puts "Skipping nil answer for #{item.id}"
      return
    end

    answer = item.record.answer
    puts "Generating name for #{answer.id} (#{index + 1} / #{total})"

    filename = "nemo-#{answer.response.shortcode}"
    filename = build_filename(filename, item)
    item.blob.update!(filename: filename)
  end

  # Note: Intentionally duplicated code, see app/models/media/object.rb.
  def build_filename(filename, item)
    repeat_groups = []
    answer = item.record.answer
    answer_group = nil
    answer_group = next_agroup_up(answer.parent_id) if answer.from_group? && answer.parent_id
    if answer_group.present? && answer_group.repeatable?
      repeat_groups = respect_ancestors(answer_group, repeat_groups)
      filename += "-#{repeat_groups.pop}" until repeat_groups.empty?
    end
    filename += "-#{answer.question.code}"
    filename += File.extname(item.filename.to_s)
    filename.gsub(/[^0-9A-Za-z.\-]/, "_")
  end

  # Note: Intentionally duplicated code, see app/models/media/object.rb.
  def respect_ancestors(answer_group, repeat_groups)
    name = answer_group.group_name
    name += (answer_group.new_rank + 1).to_s if answer_group.repeatable?
    repeat_groups << name
    if answer_group.parent_id.present?
      parent_answer_group = next_agroup_up(answer_group.parent_id)
      if parent_answer_group.present? && parent_answer_group.group_name.present?
        repeat_groups = respect_ancestors(parent_answer_group, repeat_groups)
      end
    end
    repeat_groups
  end

  # Note: Intentionally duplicated code, see app/models/media/object.rb.
  def next_agroup_up(agroup_id)
    parent = ResponseNode.find(agroup_id)
    if parent.type != "AnswerGroup" && parent.parent_id.present?
      next_agroup_up(parent.parent_id)
    else
      parent
    end
  end
end
