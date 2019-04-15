import pick from 'lodash/pick';
import React from 'react';
import { shallow, mount } from 'enzyme';
import { Provider } from 'mobx-react';

import { STUB_COMPONENT_WARNINGS, suppressErrors, unsuppressAllErrors } from '../../testUtils';
import { filtersStore } from './utils';

import { CONTROLLER_NAME } from '../../../../app/javascript/components/search/utils';
import { FiltersRoot as Component } from '../../../../app/javascript/components/search/Filters';
import { SUBMITTER_TYPES, submitterType } from '../../../../app/javascript/components/search/SubmitterFilter';

const defaultProps = {
  // Pass in initial props.
  ...pick(filtersStore, ['allForms', 'selectedFormIds', 'isReviewed', 'advancedSearchText']),
  allUsers: filtersStore.allSubmittersForType[submitterType.USER],
  selectedUsers: filtersStore.selectedSubmitterIdsForType[submitterType.USER],
  allGroups: filtersStore.allSubmittersForType[submitterType.GROUP],
  selectedGroups: filtersStore.selectedSubmitterIdsForType[submitterType.GROUP],
  controllerName: CONTROLLER_NAME.RESPONSES,
};

const defaultPropsWithStore = {
  ...defaultProps,
  filtersStore,
  conditionSetStore: filtersStore.conditionSetStore,
};

it('renders as expected (responses page)', () => {
  const wrapper = shallow(<Component {...defaultPropsWithStore} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders as expected (other page)', () => {
  const wrapper = shallow(
    <Component
      {...defaultPropsWithStore}
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
  const { FiltersRoot: Component } = require('../../../../app/javascript/components/search/Filters');

  suppressErrors(STUB_COMPONENT_WARNINGS);
  const wrapper = mount(
    <Provider filtersStore={filtersStore} conditionSetStore={filtersStore.conditionSetStore}>
      <Component {...defaultProps} />
    </Provider>,
  );
  unsuppressAllErrors();

  beforeEach(() => {
    window.location.assign.mockClear();
  });

  it('navigates on apply form filter', () => {
    wrapper.find('Button#form-filter').simulate('click');
    const overlay = shallow(wrapper.find('OverlayTrigger#form-filter').prop('overlay'));
    overlay.find('Select2').simulate('change', { target: { value: filtersStore.allForms[0].id } });

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
      const value = filtersStore.allSubmittersForType[type][0].id;
      overlay.find(`Select2#${type}`).simulate('change', { target: { value } });
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
