import React from "react";
import {shallow} from "enzyme";

import Component from "../../../../app/javascript/components/search_filters/FormFilter";

const defaultProps = {
  allForms: [
    {
      id: "1",
      displayName: "One"
    },
    {
      id: "1",
      displayName: "One"
    }
  ],
  selectedFormIds: [
    "2"
  ]
};

it("renders as expected", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});
