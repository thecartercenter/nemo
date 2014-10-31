// ELMO.Views.QuestionFormTagField
//
// View model for Tags field on Question form
(function(ns, klass) {

  // constructor
  ns.QuestionFormTagField = klass = function(params) { var self = this;
    self.params = params;

    $('#question_tag_ids').tokenInput(params.suggest_tags_path + '.json', {
      theme: 'elmo',
      jsonContainer: 'tags',
      hintText: I18n.t('tag.type_to_add_new'),
      noResultsText: I18n.t('tag.none_found'),
      searchingText: I18n.t('tag.searching'),
      resultsFormatter: self.format_token_result,
      tokenFormatter: self.format_token,
      prePopulate: params.question_tags,
      onAdd: function(item) { self.add_tag(item, params.mission_id) },
      onDelete: self.remove_tag,
    });
  };

  // If tag doesn't already exist, append hidden inputs to add it via nested attributes
  klass.prototype.add_tag = function(item, mission_id) {
    var selector = 'input[name="question[tags_attributes][][name]"][value="'+item.name+'"]';
    // if new item (null id) and hasn't already been added to this page
    if (item.id == null && $(selector).length == 0) {
      var is_standard = (mission_id == '' ? '1' : '0');
      $('.question_form').append(
              '<input type="hidden" name="question[tags_attributes][][name]" value="'+item.name+'">' +
              '<input type="hidden" name="question[tags_attributes][][mission_id]" value="'+mission_id+'">' +
              '<input type="hidden" name="question[tags_attributes][][is_standard]" value="'+is_standard+'">'
      );
    }
  };

  // If previously added new tag input, remove it
  klass.prototype.remove_tag = function(item) {
    if (item.id == null && $.inArray(item, $('#question_tag_ids').tokenInput('get')) == -1) {
      $('input[name="question[tags_attributes][][name]"][value="'+item.name+'"]').remove();
    }
  };

  // returns the html to insert in the token input result list
  klass.prototype.format_token_result = function(item) {
    // if this is the new placeholder, add a string about that
    if (item.id == null) {
      return '<li><i class="fa fa-fw fa-plus-circle"></i> ' + item.name +
          ' <span class="details create_new">[' + I18n.t('tag.new_tag') + ']</span>' + '</li>';
    } else if (item.mission_id == null) { // standard tag
      return '<li><i class="fa fa-fw fa-certificate"></i> ' + item.name + '</li>';
    } else {
      return '<li><i class="fa fa-fw"></i> ' + item.name + '</li>';
    }
  };

  // returns the html to display the tokens in the input field
  klass.prototype.format_token = function(item) {
    // if this is a new tag, add an icon
    if (item.id == null) {
      return '<li><i class="fa fa-plus-circle"></i> ' + item.name + '</li>';
    } else if (item.mission_id == null) { // standard tag
      return '<li><i class="fa fa-certificate"></i> ' + item.name + '</li>';
    } else {
      return '<li>' + item.name + '</li>';
    }
  };

}(ELMO.Views));
