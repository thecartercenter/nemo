// Builds options for select2 controls so that common options can be reused without duplication.
// It's designed like this, instead of as a wrapper of select2, so it can be used in React as well
// as Backbone.
ELMO.Utils.Select2OptionBuilder = class Select2OptionBuilder {
  ajax(url, resultsKey = 'results', textKey = 'text') {
    return {
      url,
      dataType: 'json',
      delay: 250,
      data(params) {
        return {
          search: params.term,
          page: params.page,
        };
      },
      processResults(data) {
        const results = data[resultsKey];
        if (textKey !== 'text') {
          // eslint-disable-next-line no-param-reassign
          results.forEach((r) => { r.text = r[textKey]; });
        }
        return { results, pagination: { more: data.more } };
      },
      cache: true,
    };
  }
};
