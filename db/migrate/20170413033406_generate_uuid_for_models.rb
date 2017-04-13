MODELS_WITH_UUIDS = [Answer, Assignment, BroadcastAddressing, Broadcast, Choice, Condition,
  FormForwarding, FormItem, FormVersion, Form, Media::Object, Mission, Operation, OptionNode, OptionSet, Option,
  Question, Report::Calculation, Report::OptionSetChoice, Report::Report, Response, Setting, Sms::Message,
  Tag, Tagging, UserGroupAssignment, UserGroup, User, Whitelisting]

class GenerateUuidForModels < ActiveRecord::Migration
  def up
    MODELS_WITH_UUIDS.each do |model|
      model.find_each do |instance|
        instance.uuid = SecureRandom.uuid
        instance.save!
      end
    end
  end

  def down
    MODELS_WITH_UUIDS.each do |model|
      model.update_all(uuid: nil)
    end
  end
end
