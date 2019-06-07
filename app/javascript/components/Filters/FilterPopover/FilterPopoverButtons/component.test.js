import React from 'react';
import { shallow } from 'enzyme/build';

import Component from './component';

const defaultProps = {
  onSubmit: jest.fn(),
  containerClass: 'class',
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});
