import React from "react";
import {shallow} from "enzyme";

import {advancedSearchProps} from "./utils";

import Component from "../../../../app/javascript/components/search/AdvancedSearchFilter";

const defaultProps = {
  ...advancedSearchProps,
  onChangeAdvancedSearch: jest.fn(),
  onSubmit: jest.fn(),
};

it("renders as expected", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

it("handles callbacks", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  wrapper.find("Button.btn-apply").simulate("click");

  expect(defaultProps.onSubmit).toMatchSnapshot();
});
