import React from 'react';
import { shallow } from 'enzyme';

import { getFiltersStore } from '../testUtils';

import Component from './component';

const defaultProps = {
  filtersStore: getFiltersStore(),
  onSubmit: jest.fn(),
  onClear: jest.fn(),
};

function withQueryParam() {
  window.location.search = '?search=foo';
}

function withoutQueryParam() {
  window.location.search = '?search=';
}

it('renders as expected (without query param)', () => {
  withoutQueryParam();
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders as expected (with query param)', () => {
  withQueryParam();
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders as expected (with info button)', () => {
  const wrapper = shallow(<Component {...defaultProps} renderInfoButton />);
  expect(wrapper).toMatchSnapshot();
});

describe('callbacks', () => {
  withQueryParam();
  const wrapper = shallow(<Component {...defaultProps} />);

  it('submits', () => {
    wrapper.find('Button.btn-apply').simulate('click');
    expect(defaultProps.onSubmit).toMatchSnapshot();
  });
});
