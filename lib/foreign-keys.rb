# A hash representing all foreign keys in the db and which tables they point to.
FOREIGN_KEYS = {
  'answers' => [
    {col: 'response_id'},
    {col: 'option_id'},
    {col: 'questioning_id'}
  ],

  'assignments' => [
    {col: 'mission_id'},
    {col: 'user_id'}
  ],

  'broadcast_addressings' => [
    {col: 'broadcast_id'},
    {col: 'user_id'}
  ],

  'broadcasts' => [
    {col: 'mission_id'}
  ],

  'choices' => [
    {col: 'answer_id'},
    {col: 'option_id'}
  ],

  'conditions' => [
    {col: 'questioning_id'},
    {col: 'ref_qing_id', ref_tbl: 'questionings'},
    {col: 'option_id'},
    {col: 'mission_id', no_rev: true}
  ],

  'form_versions' => [
    {col: 'form_id', no_fwd: true}
  ],

  'forms' => [
    {col: 'mission_id', no_rev: true},
    {col: 'current_version_id', ref_tbl: 'form_versions'},
    {col: 'original_id', ref_tbl: 'forms'}
  ],

  'groups' => [
    {col: 'mission_id'}
  ],

  'missions' => [],

  'option_nodes' => [
    {col: 'option_set_id'},
    {col: 'ancestry', ancestry: true},
    {col: 'option_id', no_rev: true},
    {col: 'mission_id', no_rev: true}
  ],

  'option_sets' => [
    {col: 'mission_id', no_rev: true},
    {col: 'original_id', ref_tbl: 'option_sets'},
    {col: 'root_node_id', ref_tbl: 'option_nodes', no_rev: true}
  ],

  'options' => [
    {col: 'mission_id', no_rev: true}
  ],

  'questionings' => [
    {col: 'question_id', no_rev: true},
    {col: 'form_id', no_fwd: true},
    {col: 'mission_id', no_rev: true}
  ],

  'questions' => [
    {col: 'option_set_id', no_rev: true},
    {col: 'mission_id', no_rev: true},
    {col: 'original_id', ref_tbl: 'questions'}
  ],

  'report_calculations' => [
    {col: 'report_report_id'},
    {col: 'question1_id', ref_tbl: 'questions'}
  ],

  'report_option_set_choices' => [
    {col: 'report_report_id'},
    {col: 'option_set_id'}
  ],

  'report_reports' => [
    {col: 'mission_id'},
    {col: 'form_id'},
    {col: 'disagg_qing_id', ref_tbl: 'questionings'}
  ],

  'responses' => [
    {col: 'form_id'},
    {col: 'user_id'},
    {col: 'mission_id'}
  ],

  'settings' => [
    {col: 'mission_id'}
  ],

  'sms_messages' => [
    {col: 'mission_id'}
  ],

  # 'taggings' => [
  #   {col: 'question_id'},
  #   {col: 'tag_id'}
  # ],
  #
  # 'tags' => [
  #   {col: 'mission_id'},
  #   {col: 'original_id', ref_tbl: 'tags'}
  # ],

  'user_groups' => [
    {col: 'user_id'},
    {col: 'group_id'}
  ],

  'users' => [
    {col: 'last_mission_id', ref_tbl: 'missions'}
  ],

  'whitelists' => [
    {col: 'user_id'},
    {col: 'whitelistable_id', polymorphic: true}
  ]
}
