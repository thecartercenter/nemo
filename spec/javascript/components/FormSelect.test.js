import React from "react";
import renderer from "react-test-renderer";

import Component from "../../../app/javascript/components/FormSelect";

const defaultProps = {
  id: "1",
  options: [
    { id: "1", name: "First" },
    { id: "2", name: "Second" },
  ],
};

it("renders as expected", () => {
  const tree = renderer.create(<Component {...defaultProps} />);
  expect(tree.toJSON()).toMatchSnapshot();
});
