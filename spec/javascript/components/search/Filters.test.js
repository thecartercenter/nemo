import pick from 'lodash/pick';
import React from 'react';
import { shallow, mount } from 'enzyme';
import { Provider } from 'mobx-react';

import { STUB_COMPONENT_WARNINGS, suppressErrors, unsuppressAllErrors } from '../../testUtils';
import { getFiltersStore } from './utils';

import { CONTROLLER_NAME } from '../../../../app/javascript/components/search/utils';
import { FiltersRoot as Component } from '../../../../app/javascript/components/Filters/Filters';
import { SUBMITTER_TYPES, submitterType } from '../../../../app/javascript/components/SubmitterFilter/SubmitterFilter';

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
  const { FiltersRoot: Component } = require('../../../../app/javascript/components/Filters/Filters');

  let wrapper;

  beforeEach(() => {
    window.location.assign.mockClear();

    resetDefaultProps();

    suppressErrors(STUB_COMPONENT_WARNINGS);
    wrapper = mount(
      <Provider
        filtersStore={defaultProps.filtersStore}
        conditionSetStore={defaultProps.filtersStore.conditionSetStore}
      >
        <Component {...defaultProps} />
      </Provider>,
    );
    unsuppressAllErrors();
  });

  it('navigates on apply form filter', () => {
    wrapper.find('Button#form-filter').simulate('click');
    const overlay = shallow(wrapper.find('OverlayTrigger#form-filter').prop('overlay'));
    // Call prop directly since Select2 is stubbed out.
    overlay.find('Select2').prop('onSelect')({ target: { value: defaultProps.filtersStore.allForms[0].id } });

    expect(window.location.assign).toMatchSnapshot();
    overlay.find('Button.btn-apply').simulate('click');
    expect(window.location.assign).toMatchSnapshot();
  });

  it('navigates on apply question filter', () => {
    wrapper.find('Button#question-filter').simulate('click');
    const overlay = shallow(wrapper.find('OverlayTrigger#question-filter').prop('overlay'));

    expect(window.location.assign).toMatchSnapshot();
    overlay.find('Button.btn-apply').simulate('click');
    expect(window.location.assign).toMatchSnapshot();
  });

  it('navigates on apply reviewed filter', () => {
    wrapper.find('Button#reviewed-filter').simulate('click');
    const overlay = shallow(wrapper.find('OverlayTrigger#reviewed-filter').prop('overlay'));
    overlay.find('#no').simulate('click');

    expect(window.location.assign).toMatchSnapshot();
    overlay.find('Button.btn-apply').simulate('click');
    expect(window.location.assign).toMatchSnapshot();
  });

  it('navigates on apply submitter filter', () => {
    wrapper.find('Button#submitter-filter').simulate('click');
    const overlay = shallow(wrapper.find('OverlayTrigger#submitter-filter').prop('overlay'));

    SUBMITTER_TYPES.forEach((type) => {
      const { id, name } = defaultProps.filtersStore.allSubmittersForType[type][0];
      // Call prop directly since Select2 is stubbed out.
      overlay.find(`Select2#${type}`).prop('onSelect')({ params: { data: { id, text: name } } });
    });

    expect(window.location.assign).toMatchSnapshot();
    overlay.find('Button.btn-apply').simulate('click');
    expect(window.location.assign).toMatchSnapshot();
  });

  it('navigates on apply advanced search', () => {
    wrapper.find('.search-str').simulate('change', { target: { value: 'something else' } });

    expect(window.location.assign).toMatchSnapshot();
    wrapper.find('Button.btn-advanced-search').simulate('click');
    expect(window.location.assign).toMatchSnapshot();
  });
});
