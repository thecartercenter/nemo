import React from 'react';
import { shallow, mount } from 'enzyme';

import { STUB_COMPONENT_WARNINGS, suppressErrors, unsuppressAllErrors } from '../../testUtils';
import { allFilterProps } from './utils';

import { CONTROLLER_NAME } from '../../../../app/javascript/components/search/utils';
import Component from '../../../../app/javascript/components/search/Filters';

const defaultProps = {
  ...allFilterProps,
  controllerName: CONTROLLER_NAME.RESPONSES,
};

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
  suppressErrors(STUB_COMPONENT_WARNINGS);
  const wrapper = mount(<Component {...defaultProps} />);
  unsuppressAllErrors();

  beforeEach(() => window.location.assign.mockClear());

  it('navigates on apply form filter', () => {
    wrapper.find('Button.btn-form-filter').simulate('click');
    const overlay = shallow(wrapper.find('OverlayTrigger').prop('overlay'));
    overlay.find('Select2').simulate('change', { target: { value: defaultProps.allForms[0].id } });

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
