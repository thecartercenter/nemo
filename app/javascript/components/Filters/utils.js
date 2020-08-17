import isEmpty from 'lodash/isEmpty';
import mapKeys from 'lodash/mapKeys';
import queryString from 'query-string';

import { SUBMITTER_TYPES } from './SubmitterFilter/utils';

const MAX_HINTS_BEFORE_ELLIPSIZE = 1;

/**
 * Stringified controller_name from Rails.
 */
export const CONTROLLER_NAME = {
  RESPONSES: '"responses"',
};

/**
 * Returns a new instance of FiltersModel.
 *
 * Generally this should be added to a top-level Provider and only used once.
 */
export function provideFiltersStore(FiltersModel, initialState) {
  const store = new FiltersModel(initialState);

  if (process.env.NODE_ENV === 'development') {
    // Debug helper.
    window.store = store;
  }

  return store;
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

  const dateParts = [];
  if (startDate) {
    dateParts.push(`submit-date>=${startDate.format('YYYY-MM-DD')}`);
  }
  if (endDate) {
    dateParts.push(`submit-date<=${endDate.format('YYYY-MM-DD')}`);
  }

  const parts = [
    isEmpty(selectedFormIds) ? null : `form-id:(${selectedFormIds.join('|')})`,
    ...questionFilters,
    isReviewed == null ? null : `reviewed:${isReviewed ? '1' : '0'}`,
    ...submitterParts,
    dateParts.join(' '),
    advancedSearchText,
  ].filter(Boolean);

  return parts.join(' ');
}

/**
 * Reload the page with the given search,
 * resetting the page number.
 */
export function submitSearch(filterString) {
  const parsed = queryString.parse(window.location.search);
  // Params will be removed from the URL if `undefined`.
  const search = filterString || undefined;
  const page = undefined;
  const params = queryString.stringify({ ...parsed, search, page });

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
