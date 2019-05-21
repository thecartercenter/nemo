select2 = {
  getAjaxParams: (url, resultsKey = 'results') ->
    url: url
    dataType: 'json'
    delay: 250,
    data: (params) ->
      search: params.term
      page: params.page
    processResults: (data) ->
      results: data[resultsKey]
      pagination: {more: data.more}
    cache: true
}

ELMO.select2 = select2
