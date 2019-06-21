# Builds options for select2 controls so that common options can be reused without duplication.
# It's designed like this, instead of as a wrapper of select2, so it can be used in React as well
# as Backbone.
class ELMO.Utils.Select2OptionBuilder
  ajax: (url, resultsKey = 'results', textKey = 'text') ->
    url: url
    dataType: 'json'
    delay: 250,
    data: (params) ->
      search: params.term
      page: params.page
    processResults: (data) ->
      results = data[resultsKey]
      results.forEach((r) -> r['text'] = r[textKey]) unless textKey == 'text'
      {results: results, pagination: {more: data.more}}
    cache: true
