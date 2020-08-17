import {
  getButtonHintString,
  getItemNameFromId,
  getFilterString,
  submitSearch,
  isQueryParamTruthy,
} from './utils';
import { getEmptySubmitterTypeMap } from './model';

import { getFiltersStore } from './testUtils';

it('gets hints (0)', () => {
  const result = getButtonHintString([]);
  expect(result).toMatchSnapshot();
});

it('gets hints (small number)', () => {
  const result = getButtonHintString(['one']);
  expect(result).toMatchSnapshot();
});

it('gets hints (too many)', () => {
  const result = getButtonHintString(['one', 'two', 'three']);
  expect(result).toMatchSnapshot();
});

it('gets item name (found)', () => {
  const result = getItemNameFromId([{ id: '1', name: 'One' }], '1');
  expect(result).toMatchSnapshot();
});

it('gets item name (not found)', () => {
  const result = getItemNameFromId([], '1');
  expect(result).toMatchSnapshot();
});

it('gets filter string (no filters)', () => {
  const filtersStore = getFiltersStore();
  const emptyFilters = {
    ...filtersStore,
    selectedFormIds: [],
    conditionSetStore: {
      ...filtersStore.conditionSetStore,
      conditions: [],
    },
    isReviewed: null,
    selectedSubmittersForType: getEmptySubmitterTypeMap(),
    advancedSearchText: '',
  };

  const result = getFilterString(emptyFilters);
  expect(result).toMatchSnapshot();
});

it('gets filter string (all filters)', () => {
  const populatedFilters = {
    ...getFiltersStore(),
    selectedFormIds: ['1', '3'],
    advancedSearchText: 'query',
  };

  const result = getFilterString(populatedFilters);
  expect(result).toMatchSnapshot();
});

it('submits searches', () => {
  // Page should go away after search, but other params should pass through.
  window.location.search = '?foo=bar&page=2';
  expect(window.location.assign.mock.calls).toMatchSnapshot();

  submitSearch('foo');
  expect(window.location.assign.mock.calls).toMatchSnapshot();

  window.location.assign.mockClear();
  submitSearch(null);
  expect(window.location.assign.mock.calls).toMatchSnapshot();

  window.location.assign.mockClear();
  window.location.search = '?';
  submitSearch(null);
  expect(window.location.assign.mock.calls).toMatchSnapshot();
});

it('checks if param is truthy', () => {
  window.location.search = '?foo=&bar=baz';
  expect(isQueryParamTruthy('foo')).toMatchSnapshot();
  expect(isQueryParamTruthy('bar')).toMatchSnapshot();
  expect(isQueryParamTruthy('baz')).toMatchSnapshot();
});
