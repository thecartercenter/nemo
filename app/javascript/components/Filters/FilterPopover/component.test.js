import React from 'react';
import { shallow } from 'enzyme';

import Component from './component';

const defaultProps = {
  children: <div>Test</div>,
  id: 'id',
  className: 'class',
  onSubmit: jest.fn(),
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});
