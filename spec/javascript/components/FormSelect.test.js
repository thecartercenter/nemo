import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";

import Component from "../../../app/javascript/components/FormSelect";

const changeFunc = jest.fn();

const defaultProps = {
  id: "root",
  options: [
    { id: "item1", name: "First" },
    { id: "item2", name: "Second" },
  ],
  changeFunc,
};

it("renders as expected", () => {
  const tree = renderer.create(<Component {...defaultProps} />);
  expect(tree.toJSON()).toMatchSnapshot();
});

describe("after changing value", () => {
  const wrapper = shallow(<Component {...defaultProps} />);
  wrapper.find("select").simulate("change", { target: { value: defaultProps.options[0].id } });

  it("calls changeFunc", () => {
    expect(changeFunc).toMatchSnapshot();
  });

  it("renders as expected", () => {
    expect(wrapper).toMatchSnapshot();
  });
});
