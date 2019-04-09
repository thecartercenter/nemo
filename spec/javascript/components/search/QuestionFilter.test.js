import React from 'react';
import { shallow } from 'enzyme';

import { filtersStore } from './utils';

import Component from '../../../../app/javascript/components/search/QuestionFilter';

const defaultProps = {
  filtersStore,
  onSubmit: jest.fn(),
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

describe('popover', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  wrapper.find('Button#question-filter').simulate('click');

  const overlay = shallow(wrapper.find('OverlayTrigger').prop('overlay'));

  it('renders as expected', () => {
    expect(overlay).toMatchSnapshot();
  });

  it('handles callbacks', () => {
    overlay.find('Button.btn-apply').simulate('click');
    expect(defaultProps.onSubmit).toMatchSnapshot();
  });
});
