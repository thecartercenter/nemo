import React from 'react';
import { shallow } from 'enzyme';

import Component from '../../../app/javascript/components/ErrorBoundary';

const mockProps = {
  message: 'message',
  children: 'children',
};

const DangerousComponent = () => {
  throw new Error();
};

it('renders (default)', () => {
  const wrapper = shallow(<Component {...mockProps} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders (error)', () => {
  const wrapper = shallow(
    <Component {...mockProps}>
      <DangerousComponent />
    </Component>,
  );
  expect(wrapper).toMatchSnapshot();
});
