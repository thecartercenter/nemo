import pick from 'lodash/pick';
import React from 'react';
import { shallow } from 'enzyme';
import { Provider } from 'mobx-react';

import { quietMount } from '../../testUtils';
import { getFiltersStore } from './testUtils';

import { CONTROLLER_NAME } from './utils';
import Component from './component';
import { SUBMITTER_TYPES, submitterType } from './SubmitterFilter/utils';

jest.mock('../conditions/ConditionSetFormField/component', () => 'ConditionSetFormField');
jest.mock('../conditions/AddConditionLink/component', () => 'AddConditionLink');

let defaultProps = {};
resetDefaultProps();

function resetDefaultProps() {
  const filtersStore = getFiltersStore();

  defaultProps = {
    filtersStore,
    conditionSetStore: filtersStore.conditionSetStore,

    // Initial props.
    ...pick(filtersStore, ['allForms', 'selectedFormIds', 'isReviewed', 'advancedSearchText']),
    allUsers: filtersStore.allSubmittersForType[submitterType.USER],
    selectedUsers: filtersStore.selectedSubmittersForType[submitterType.USER],
    allGroups: filtersStore.allSubmittersForType[submitterType.GROUP],
    selectedGroups: filtersStore.selectedSubmittersForType[submitterType.GROUP],
    controllerName: CONTROLLER_NAME.RESPONSES,
  };
}

it('renders as expected (responses page)', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders as expected (other page)', () => {
  const wrapper = shallow(
    <Component
      {...defaultProps}
      controllerName="foo"
    />,
  );
  expect(wrapper).toMatchSnapshot();
});

describe('integration', () => {
  // Re-import Filters with unmocked @inject decorator so we can deep render.
  jest.resetModules();
  jest.unmock('mobx-react');
  // eslint-disable-next-line no-shadow
  const Component = require('./component').default;

  let wrapper;

  beforeEach(() => {
    window.location.assign.mockClear();

    resetDefaultProps();

    wrapper = quietMount(
      <Provider
        filtersStore={defaultProps.filtersStore}
        conditionSetStore={defaultProps.filtersStore.conditionSetStore}
      >
        <Component {...defaultProps} />
      </Provider>,
    );
  });

  it('navigates on apply form filter', () => {
    wrapper.find('Button#form-filter').simulate('click');
    const overlay = quietMount(wrapper.find('OverlayTrigger#form-filter').prop('overlay'));
    // Call prop directly since Select2 is stubbed out.
    overlay.find('Select2').prop('onSelect')({ target: { value: defaultProps.filtersStore.allForms[0].id } });

    expectLocationToChangeOnClick(overlay.find('Button.btn-apply'));
  });

  it('navigates on apply question filter', () => {
    wrapper.find('Button#question-filter').simulate('click');
    const overlay = quietMount(wrapper.find('OverlayTrigger#question-filter').prop('overlay'));

    expectLocationToChangeOnClick(overlay.find('Button.btn-apply'));
  });

  it('navigates on apply reviewed filter', () => {
    wrapper.find('Button#reviewed-filter').simulate('click');
    const overlay = quietMount(wrapper.find('OverlayTrigger#reviewed-filter').prop('overlay'));
    overlay.find('#no').simulate('click');

    expectLocationToChangeOnClick(overlay.find('Button.btn-apply'));
  });

  it('navigates on apply submitter filter', () => {
    wrapper.find('Button#submitter-filter').simulate('click');
    const overlay = quietMount(wrapper.find('OverlayTrigger#submitter-filter').prop('overlay'));

    SUBMITTER_TYPES.forEach((type) => {
      const { id, name } = defaultProps.filtersStore.allSubmittersForType[type][0];
      // Call prop directly since Select2 is stubbed out.
      overlay.find(`Select2#${type}`).prop('onSelect')({ params: { data: { id, text: name } } });
    });

    expectLocationToChangeOnClick(overlay.find('Button.btn-apply'));
  });

  it('navigates on apply advanced search', () => {
    wrapper.find('.search-str').simulate('change', { target: { value: 'something else' } });
    expectLocationToChangeOnClick(wrapper.find('Button.btn-advanced-search'));
  });
});

function expectLocationToChangeOnClick(element) {
  expect(window.location.assign.mock.calls.length).toBe(0);
  element.simulate('click');
  expect(window.location.assign.mock.calls.length).toBe(1);
  expect(window.location.assign.mock.calls[0]).toMatchSnapshot();
}
