import React from "react";
import {shallow} from "enzyme";

import Component from "../../../../app/javascript/components/search/Filters";

const defaultProps = {
  allForms: [],
  selectedFormIds: []
};

it("renders as expected", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});
