export function select2AjaxParams(url, resultsKey = 'results') {
  return {
    url,
    dataType: 'json',
    delay: 250,
    data: ({ term: search, page }) => ({
      search,
      page,
    }),
    processResults: ({ [resultsKey]: results, more }) => ({
      results,
      pagination: { more },
    }),
    cache: true,
  };
}
