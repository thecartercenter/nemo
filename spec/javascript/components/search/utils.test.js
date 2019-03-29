import {
  getButtonHintString,
  getFormNameFromId,
  getFilterString,
  submitSearch,
  isQueryParamTruthy,
} from '../../../../app/javascript/components/search/utils';
import { formFilterProps } from './utils';

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

it('gets form name (found)', () => {
  const result = getFormNameFromId([{ id: '1', name: 'One' }], '1');
  expect(result).toMatchSnapshot();
});

it('gets form name (not found)', () => {
  const result = getFormNameFromId([], '1');
  expect(result).toMatchSnapshot();
});

it('gets filter string (no filters)', () => {
  const emptyFilters = {
    selectedFormIds: [],
    advancedSearchText: null,
  };

  const result = getFilterString(formFilterProps.allForms, emptyFilters);
  expect(result).toMatchSnapshot();
});

it('gets filter string (all filters)', () => {
  const populatedFilters = {
    selectedFormIds: ['1', '3'],
    advancedSearchText: 'query',
  };

  const result = getFilterString(formFilterProps.allForms, populatedFilters);
  expect(result).toMatchSnapshot();
});

it('submits searches', () => {
  window.location.search = '?foo=bar';
  expect(window.location.assign).toMatchSnapshot();

  submitSearch('foo');
  expect(window.location.assign).toMatchSnapshot();

  window.location.assign.mockClear();
  submitSearch(null);
  expect(window.location.assign).toMatchSnapshot();

  window.location.assign.mockClear();
  window.location.search = '?';
  submitSearch(null);
  expect(window.location.assign).toMatchSnapshot();
});

it('checks if param is truthy', () => {
  window.location.search = '?foo=&bar=baz';
  expect(isQueryParamTruthy('foo')).toMatchSnapshot();
  expect(isQueryParamTruthy('bar')).toMatchSnapshot();
  expect(isQueryParamTruthy('baz')).toMatchSnapshot();
});
