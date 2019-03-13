import React from "react";
import {shallow} from "enzyme";

import {advancedSearchProps} from "./utils";

import Component from "../../../../app/javascript/components/search/AdvancedSearchFilter";

const defaultProps = {
  ...advancedSearchProps,
  onChangeAdvancedSearch: jest.fn(),
  onSubmit: jest.fn(),
  onClear: jest.fn(),
};

it("renders as expected", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

describe("callbacks", () => {
  const wrapper = shallow(<Component {...defaultProps} />);

  it("submits", () => {
    wrapper.find("Button.btn-apply").simulate("click");
    expect(defaultProps.onSubmit).toMatchSnapshot();
  });

  it("clears", () => {
    wrapper.find("Button.btn-clear").simulate("click");
    expect(defaultProps.onClear).toMatchSnapshot();
  });
});
