import React from "react";
import {shallow} from "enzyme";

import Component from "../../../../app/javascript/components/search/FormFilter";

const defaultProps = {
  allForms: [
    {
      id: "1",
      displayName: "One"
    },
    {
      id: "2",
      displayName: "Two"
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

describe("popover", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  wrapper.find("Button.btn-form-filter").simulate("click");

  const overlay = shallow(wrapper.find("OverlayTrigger").prop("overlay"));

  it("renders as expected", () => {
    expect(overlay).toMatchSnapshot();
  });

  overlay.find("Select2").simulate("change", {target: {value: defaultProps.allForms[0].id}});
  overlay.find("Button.btn-apply").simulate("click");

  // TODO: Validate window.location.href is updated.
});
