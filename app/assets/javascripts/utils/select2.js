export function select2AjaxParams(url) {
  return {
    url,
    dataType: 'json',
    delay: 250,
    data: ({ term: search, page }) => ({
      search,
      page,
    }),
    processResults: ({ possible_users: results, more }) => ({
      results,
      pagination: { more },
    }),
    cache: true,
  };
}
