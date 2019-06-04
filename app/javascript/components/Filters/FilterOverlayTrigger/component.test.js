import React from 'react';
import { shallow } from 'enzyme';

import Component from './component';

const defaultProps = {
  id: 'id',
  title: 'title',
  overlay: 'overlay',
  hints: ['hint'],
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});
