import React from 'react';
import { shallow } from 'enzyme';

import { formFilterProps } from './utils';

import Component from '../../../../app/javascript/components/search/FormFilter';

const defaultProps = {
  ...formFilterProps,
  onSelectForm: jest.fn(),
  onClearSelection: jest.fn(),
  onSubmit: jest.fn(),
};

it('renders as expected', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

describe('popover', () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  wrapper.find('Button.btn-form-filter').simulate('click');

  const overlay = shallow(wrapper.find('OverlayTrigger').prop('overlay'));

  it('renders as expected', () => {
    expect(overlay).toMatchSnapshot();
  });

  it('handles callbacks', () => {
    overlay.find('Select2').simulate('change', { target: { value: defaultProps.allForms[0].id } });
    overlay.find('Button.btn-apply').simulate('click');

    expect(defaultProps.onSubmit).toMatchSnapshot();
  });
});
