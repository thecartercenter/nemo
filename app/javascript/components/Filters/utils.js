import isEmpty from 'lodash/isEmpty';
import mapKeys from 'lodash/mapKeys';
import queryString from 'query-string';
import moment from 'moment';
import { last } from 'lodash';

import { SUBMITTER_TYPES } from './SubmitterFilter/utils';

const MAX_HINTS_BEFORE_ELLIPSIZE = 1;

/**
 * Stringified controller_name from Rails.
 */
export const CONTROLLER_NAME = {
  RESPONSES: '"responses"',
};

/** Cache. */
let filtersStore = null;

/**
 * Returns a new instance of FiltersModel.
 *
 * Generally this should be added to a top-level Provider and only used once.
 */
export function provideFiltersStore(FiltersModel, initialState) {
  if (!filtersStore) {
    filtersStore = new FiltersModel(initialState);

    if (process.env.NODE_ENV === 'development') {
      // Debug helper.
      window.store = filtersStore;
    }
  }

  return filtersStore;
}

/**
 * Given a list of hints (e.g. currently selected form names for the form filter button),
 * stringify them to be displayed on the button itself.
 */
export function getButtonHintString(hints) {
  if (isEmpty(hints)) {
    return '';
  }

  const joinedHints = hints.length > MAX_HINTS_BEFORE_ELLIPSIZE
    ? `${hints.length} filters`
    : hints.join(', ');

  return ` (${joinedHints})`;
}

/**
 * Given an item ID, find it in the list of items and return its `name`.
 */
export function getItemNameFromId(allItems, searchId, nameKey = 'name') {
  const item = allItems.find(({ id }) => searchId === id);
  return (item && item[nameKey]) || 'Unknown';
}

/**
 * Given a leftQingId, find it in the list of all questions and return the name.
 */
export function getQuestionNameFromId(allQuestions, searchId) {
  return getItemNameFromId(allQuestions, searchId, 'code');
}

/**
 * Converts a list of data from the backend into something Select2 understands, e.g.
 * [{ id: '1', name: 'One' }, ...] => [{ id: '1', text: 'One' }, ...]
 */
export function parseListForSelect2(allItems) {
  return allItems.map((item) =>
    mapKeys(item, (value, key) => (key === 'name' ? 'text' : key)));
}

/**
 * Given all of the different filter states,
 * return a stringified version for the backend.
 */
export function getFilterString({
  selectedFormIds,
  conditionSetStore,
  isReviewed,
  selectedSubmittersForType,
  advancedSearchText,
  startDate,
  endDate,
}) {
  const allQuestions = conditionSetStore.refableQings;
  const questionFilters = conditionSetStore.conditions
    .filter(({ leftQingId, currTextValue, remove }) => leftQingId && currTextValue && !remove)
    .map(({ leftQingId, currTextValue }) =>
      `{${getQuestionNameFromId(allQuestions, leftQingId)}}:${JSON.stringify(currTextValue)}`);

  const submitterParts = SUBMITTER_TYPES.map((type) => {
    const selectedSubmitterIds = selectedSubmittersForType[type].map(({ id }) => id);
    return isEmpty(selectedSubmitterIds) ? null : `${type}-id:(${selectedSubmitterIds.join('|')})`;
  });

  // Only include one upper bound and one lower bound date. Use widest range.
  let searchDates = advancedSearchText.split(' ').filter((s) => s.indexOf('submit-date') !== -1).map(queryToMoment);
  const searchText = advancedSearchText.split(' ').filter((s) => s.indexOf('submit-date') === -1).join(' ');
  searchDates = [...searchDates, startDate, endDate].filter((d) => d !== null);
  if (searchDates.length >= 2) {
    searchDates.sort((a, b) => {
      if (a.isSameOrBefore(b)) return -1;
      return 1;
    });
  }

  let dateQueries = null;
  if (searchDates.length === 0) {
    // No-op
  } else if (searchDates.length === 1) {
    // Figure out if this was supposed to be an upper or lower bound.
    if (searchDates[0] === startDate) {
      dateQueries = `submit-date >= ${searchDates[0].format('YYYY-MM-DD')}`;
    } else if (searchDates[0] === endDate) {
      dateQueries = `submit-date <= ${searchDates[0].format('YYYY-MM-DD')}`;
    } else {
      // Date entered in search bar, use original string.
      dateQueries = advancedSearchText.split(' ').filter((s) => s.indexOf('submit-date') !== -1).join(' ');
    }
  } else {
    // Take first and last dates.
    dateQueries = `submit-date >= ${searchDates[0].format('YYYY-MM-DD')} submit-date <= ${last(searchDates).format('YYYY-MM-DD')}`;
  }

  const parts = [
    isEmpty(selectedFormIds) ? null : `form-id:(${selectedFormIds.join('|')})`,
    ...questionFilters,
    isReviewed == null ? null : `reviewed:${isReviewed ? '1' : '0'}`,
    ...submitterParts,
    searchText,
    dateQueries,
  ].filter(Boolean);

  return parts.join(' ');
}

/**
 * Reload the page with the given search.
 */
export function submitSearch(filterString) {
  const parsed = queryString.parse(window.location.search);
  // The `search` query param will be removed from the URL if it's `undefined`.
  const search = filterString || undefined;
  const params = queryString.stringify({ ...parsed, search });

  window.location.assign(params
    ? `?${params}`
    : window.location.pathname);
}

/**
 * Returns true if the given param name exists and is non-empty.
 */
export function isQueryParamTruthy(paramName) {
  const parsed = queryString.parse(window.location.search);
  return Boolean(parsed[paramName]);
}

export function queryToMoment(query) {
  if (query === null || query === undefined) return null;
  const dateString = query.split(/submit-date[<>=]+/)[1];
  // If this doesn't parse an actual date, don't use it.
  if (dateString === undefined) return null;
  const date = moment(dateString);
  if (date._isValid) { /* eslint-disable-line no-underscore-dangle */
    return date;
  }
  return null;
}
