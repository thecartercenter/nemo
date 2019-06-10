select2 = {
  getAjaxParams: (url, resultsKey = 'results', textKey = 'text') ->
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
}

ELMO.select2 = select2
