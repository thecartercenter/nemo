import React from 'react';
import { mount } from 'enzyme';

import Component from './component';

const mockProps = {
  message: 'message',
  children: 'children',
};

const DangerousComponent = () => {
  throw new Error();
};

it('renders (default)', () => {
  const wrapper = mount(<Component {...mockProps} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders (error)', () => {
  const wrapper = mount(
    <Component {...mockProps}>
      <DangerousComponent />
    </Component>,
  );
  expect(wrapper).toMatchSnapshot();
});
