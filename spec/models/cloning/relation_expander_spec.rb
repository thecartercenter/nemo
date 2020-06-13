# frozen_string_literal: true

require "rails_helper"

describe Cloning::RelationExpander do
  context "forms, users, mission" do
    let(:mission) { create(:mission, id: "11111111-1111-1111-1111-111111111111") }
    let(:expander) do
      described_class.new([Form.where(mission: mission),
                           Question.where(mission: mission),
                           Tag.where(id: "22222222-2222-2222-2222-222222222222"),
                           User.assigned_to(mission),
                           Mission.where(id: mission.id)], dont_implicitly_expand: [Question])
    end
    subject(:result) { expander.expanded }

    it "generates relations that lead to valid SQL" do
      result.values.each do |rel_array|
        rel_array.each do |rel|
          expect { SqlRunner.instance.run(rel.to_sql) }.not_to raise_error
        end
      end
    end

    it "generates relations for the right classes" do
      expect(result.keys.map(&:name)).to match_array(%w[
        Form FormVersion FormItem Question OptionSet OptionNode Option Tagging Tag Condition SkipRule
        Constraint User Assignment UserGroupAssignment UserGroup Mission Setting
      ])
    end

    it "generates relations that generate the appropriate SQL" do
      # Convert each rel in the result hash to SQL
      sql_by_class = {}
      result.each do |klass, rel_array|
        sql_by_class[klass] = rel_array.map { |rel| rel.to_sql.tr('"', "") }
      end

      expect(sql_by_class[Form][0]).to match_words(
        "SELECT forms.* FROM forms WHERE forms.mission_id = '11111111-1111-1111-1111-111111111111'"
      )
      expect(sql_by_class[FormVersion][0]).to match_words(
        "SELECT form_versions.* FROM form_versions WHERE (
          form_id IN (
            SELECT forms.id FROM forms WHERE forms.mission_id = '11111111-1111-1111-1111-111111111111'
          )
        )"
      )
      expect(sql_by_class[FormItem][0]).to match_words(
        "SELECT form_items.* FROM form_items WHERE (
          form_id IN (
            SELECT forms.id FROM forms WHERE forms.mission_id = '11111111-1111-1111-1111-111111111111'
          )
        )"
      )
      expect(sql_by_class[Question][0]).to match_words(
        "SELECT questions.* FROM questions WHERE
          questions.mission_id = '11111111-1111-1111-1111-111111111111'"
      )
      expect(sql_by_class[OptionSet][0]).to match_words(
        "SELECT option_sets.* FROM option_sets WHERE (
          id IN (
            SELECT questions.option_set_id FROM questions WHERE
              questions.mission_id = '11111111-1111-1111-1111-111111111111'
          )
        )"
      )
      expect(sql_by_class[OptionNode][0]).to match_words(
        "SELECT option_nodes.* FROM option_nodes WHERE (
          option_set_id IN (
            SELECT option_sets.id FROM option_sets WHERE (
              id IN (
                SELECT questions.option_set_id FROM questions WHERE
                  questions.mission_id = '11111111-1111-1111-1111-111111111111'
              )
            )
          )
        )"
      )
      expect(sql_by_class[Option][0]).to match_words(
        "SELECT options.* FROM options WHERE (
          id IN (
            SELECT option_nodes.option_id FROM option_nodes WHERE (
              option_set_id IN (
                SELECT option_sets.id FROM option_sets WHERE (
                  id IN (
                    SELECT questions.option_set_id FROM questions WHERE
                      questions.mission_id = '11111111-1111-1111-1111-111111111111'
                  )
                )
              )
            )
          )
        )"
      )
      expect(sql_by_class[Tagging][0]).to match_words(
        "SELECT taggings.* FROM taggings WHERE (
          question_id IN (
            SELECT questions.id FROM questions WHERE
              questions.mission_id = '11111111-1111-1111-1111-111111111111'
          )
        )"
      )
      expect(sql_by_class[Tag][0]).to match_words(
        "SELECT tags.* FROM tags WHERE tags.id = '22222222-2222-2222-2222-222222222222'"
      )
      expect(sql_by_class[Tag][1]).to match_words(
        "SELECT tags.* FROM tags WHERE (
          id IN (
            SELECT taggings.tag_id FROM taggings WHERE (
              question_id IN (
                SELECT questions.id FROM questions WHERE
                  questions.mission_id = '11111111-1111-1111-1111-111111111111'
              )
            )
          )
        )"
      )
      expect(sql_by_class[Condition][0]).to match_words(
        "SELECT conditions.* FROM conditions WHERE (
          conditionable_id IN (
            SELECT form_items.id FROM form_items WHERE (
              form_id IN (
                SELECT forms.id FROM forms WHERE
                  forms.mission_id = '11111111-1111-1111-1111-111111111111'
              )
            )
          )
        )"
      )
      expect(sql_by_class[SkipRule][0]).to match_words(
        "SELECT skip_rules.* FROM skip_rules WHERE (
          source_item_id IN (
            SELECT form_items.id FROM form_items WHERE (
              form_id IN (
                SELECT forms.id FROM forms WHERE
                  forms.mission_id = '11111111-1111-1111-1111-111111111111'
              )
            )
          )
        )"
      )
      expect(sql_by_class[Constraint][0]).to match_words(
        "SELECT constraints.* FROM constraints WHERE (
          source_item_id IN (
            SELECT form_items.id FROM form_items WHERE (
              form_id IN (
                SELECT forms.id FROM forms WHERE
                  forms.mission_id = '11111111-1111-1111-1111-111111111111'
              )
            )
          )
        )"
      )
      expect(sql_by_class[User][0]).to match_words(
        "SELECT users.* FROM users WHERE users.id IN (
          SELECT assignments.user_id FROM assignments WHERE
            assignments.mission_id = '11111111-1111-1111-1111-111111111111'
        )"
      )
      expect(sql_by_class[Assignment][0]).to match_words(
        "SELECT assignments.* FROM assignments WHERE (
          user_id IN (
            SELECT users.id FROM users WHERE users.id IN (
              SELECT assignments.user_id FROM assignments WHERE
                assignments.mission_id = '11111111-1111-1111-1111-111111111111'
            )
          )
        )"
      )
      expect(sql_by_class[UserGroupAssignment][0]).to match_words(
        "SELECT user_group_assignments.* FROM user_group_assignments WHERE (
          user_id IN (
            SELECT users.id FROM users WHERE users.id IN (
              SELECT assignments.user_id FROM assignments WHERE
                assignments.mission_id = '11111111-1111-1111-1111-111111111111'
            )
          )
        )"
      )
      expect(sql_by_class[UserGroup][0]).to match_words(
        "SELECT user_groups.* FROM user_groups WHERE (
          id IN (
            SELECT user_group_assignments.user_group_id FROM user_group_assignments WHERE (
              user_id IN (
                SELECT users.id FROM users WHERE users.id IN (
                  SELECT assignments.user_id FROM assignments WHERE
                    assignments.mission_id = '11111111-1111-1111-1111-111111111111'
                )
              )
            )
          )
        )"
      )
      expect(sql_by_class[Mission][0]).to match_words(
        "SELECT missions.* FROM missions WHERE missions.id = '11111111-1111-1111-1111-111111111111'"
      )
      expect(sql_by_class[Setting][0]).to match_words(
        "SELECT settings.* FROM settings WHERE (
          mission_id IN (
            SELECT missions.id FROM missions WHERE missions.id = '11111111-1111-1111-1111-111111111111'
          )
        )"
      )
    end
  end
end
