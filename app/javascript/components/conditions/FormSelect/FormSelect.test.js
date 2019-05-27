import React from 'react';
import { shallow } from 'enzyme';

import Component from './component';

const defaultProps = {
  id: 'root',
  options: [
    { id: 'item1', name: 'First' },
    { id: 'item2', name: 'Second' },
  ],
  onChange: jest.fn(),
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

describe('after changing value', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  wrapper.find('select').simulate('change', { target: { value: defaultProps.options[0].id } });

  it('calls onChange', () => {
    expect(defaultProps.onChange).toMatchSnapshot();
  });

  it('renders as expected', () => {
    expect(wrapper).toMatchSnapshot();
  });
});
