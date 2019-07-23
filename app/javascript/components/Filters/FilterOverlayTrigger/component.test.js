import React from 'react';
import { shallow } from 'enzyme';

import Component from './component';

const defaultProps = {
  filtersStore: {},
  id: 'id',
  title: 'title',
  popoverContent: 'content',
  popoverClass: 'popover',
  buttonsContainerClass: 'buttonsContainer',
  onSubmit: jest.fn(),
  hints: ['hint'],
  buttonClass: 'button',
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});
