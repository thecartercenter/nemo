# frozen_string_literal: true

class RenameMediaFilesToIncludeGroup < ActiveRecord::Migration[6.1]
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "Media::Object")
    attachments.includes(record: {answer: :response}).each do |attachment|
      media_object = attachment.record
      generate_media_object_filename(media_object) if media_object.present?
    end
  end

  def generate_media_object_filename(media_object)
    item = media_object.item
    return if item.record.answer_id.nil?
    answer = item.record.answer
    # this means we have already run the migration since the response code is in the filename
    return if item.blob.filename.to_s.include?(answer.response.shortcode)
    filename = "nemo-#{answer.response.shortcode}"
    filename = build_filename(filename, item)
    item.blob.update!(filename: filename)
  end

  # build a more complex filename if is nested in repeat groups
  def build_filename(filename, item)
    repeat_groups = []
    answer = item.record.answer
    answer_group = nil
    answer_group = next_agroup_up(answer.parent_id) if answer.from_group?
    if answer_group.present? && answer_group.repeatable?
      repeat_groups = respect_ancestors(answer_group, repeat_groups)
      filename += "-#{repeat_groups.pop}" until repeat_groups.empty?
      filename += File.extname(item.filename.to_s)
    else
      filename += "_#{answer.new_rank + 1}_#{item.blob.filename}"
    end
    filename.gsub(/[^0-9A-Za-z.\-]/, "_")
  end

  # returns an array of group name strings from all nested groups
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

  def next_agroup_up(agroup_id)
    parent = ResponseNode.find(agroup_id)
    if parent.type != "AnswerGroup" && parent.parent_id.present?
      next_agroup_up(parent.parent_id)
    else
      parent
    end
  end
end
