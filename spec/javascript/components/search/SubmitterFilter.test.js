import React from 'react';
import { shallow } from 'enzyme';

import { getFiltersStore } from './utils';

import Component, { SUBMITTER_TYPES } from '../../../../app/javascript/components/SubmitterFilter/SubmitterFilter';

const defaultProps = {
  filtersStore: getFiltersStore(),
  onSubmit: jest.fn(),
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

describe('popover', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  wrapper.find('Button#submitter-filter').simulate('click');

  const overlay = shallow(wrapper.find('OverlayTrigger').prop('overlay'));

  it('handles callbacks', () => {
    SUBMITTER_TYPES.forEach((type) => {
      const value = defaultProps.filtersStore.allSubmittersForType[type][0].id;
      overlay.find(`Select2#${type}`).simulate('change', { target: { value } });
    });
    overlay.find('Button.btn-apply').simulate('click');

    expect(defaultProps.onSubmit).toMatchSnapshot();
  });
});
