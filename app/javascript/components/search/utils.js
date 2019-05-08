import isEmpty from 'lodash/isEmpty';
import queryString from 'query-string';

import FiltersModel from './FiltersModel';

const MAX_HINTS_BEFORE_ELLIPSIZE = 1;

/**
 * Stringified controller_name from Rails.
 */
export const CONTROLLER_NAME = {
  RESPONSES: '"responses"',
};

/**
 * Symbol values for possible operation types.
 */
const OP_SYMBOL = {
  eq: '=',
  neq: '!=',
  gt: '>',
  lt: '<',
  geq: '>=',
  leq: '<=',
};

/** Cache. */
let filtersStore = null;

/**
 * Returns a new instance of FiltersModel.
 *
 * Generally this should be added to a top-level Provider and only used once.
 */
export function provideFiltersStore() {
  if (!filtersStore) {
    filtersStore = new FiltersModel();

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
    ? hints.length
    : hints.join(', ');

  return ` (${joinedHints})`;
}

/**
 * Given a form ID, find it in the list of all forms and return the name.
 */
export function getFormNameFromId(allForms, searchId) {
  const form = allForms.find(({ id }) => searchId === id);
  return (form && form.name) || 'Unknown';
}

/**
 * Given a refQingId, find it in the list of all questions and return the name.
 */
export function getQuestionNameFromId(allQuestions, searchId) {
  const question = allQuestions.find(({ id }) => searchId === id);
  return (question && question.code) || 'Unknown';
}

/**
 * Given all of the different filter states,
 * return a stringified version for the backend.
 */
export function getFilterString({ allForms, selectedFormIds, conditionSetStore, advancedSearchText }) {
  const selectedFormNames = selectedFormIds
    .map((id) => JSON.stringify(getFormNameFromId(allForms, id)));

  const allQuestions = conditionSetStore.refableQings;
  const questionFilters = conditionSetStore.conditions
    .filter(({ refQingId, currTextValue, remove }) => refQingId && currTextValue && !remove)
    .map(({ refQingId, currTextValue }) =>
      `{${getQuestionNameFromId(allQuestions, refQingId)}}:${JSON.stringify(currTextValue)}`);

  const parts = [
    isEmpty(selectedFormNames) ? null : `form:(${selectedFormNames.join('|')})`,
    ...questionFilters,
    advancedSearchText,
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
