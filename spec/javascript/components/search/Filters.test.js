import React from "react";
import {shallow, mount} from "enzyme";

import {STUB_COMPONENT_WARNINGS, suppressErrors, unsuppressAllErrors} from "../../testUtils";

import Component from "../../../../app/javascript/components/search/Filters";

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
  ],
};

it("renders as expected", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  expect(wrapper).toMatchSnapshot();
});

describe("integration", () => {
  suppressErrors(STUB_COMPONENT_WARNINGS);
  const wrapper = mount(<Component {...defaultProps} />);
  unsuppressAllErrors();

  it("navigates on apply form filter", () => {
    wrapper.find("Button.btn-form-filter").simulate("click");
    const overlay = shallow(wrapper.find("OverlayTrigger").prop("overlay"));
    overlay.find("Select2").simulate("change", {target: {value: defaultProps.allForms[0].id}});

    expect(window.location.assign).toMatchSnapshot();
    overlay.find("Button.btn-apply").simulate("click");
    expect(window.location.assign).toMatchSnapshot();
  });
});
