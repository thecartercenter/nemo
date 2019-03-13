import {getFilterString, submitSearch} from "../../../../app/javascript/components/search/utils";
import {formFilterProps} from "./utils";

it("gets filter string (no filters)", () => {
  const result = getFilterString([], formFilterProps.allForms);
  expect(result).toMatchSnapshot();
});

it("gets filter string (all filters)", () => {
  const result = getFilterString(["1", "2"], formFilterProps.allForms);
  expect(result).toMatchSnapshot();
});

it("submits searches", () => {
  expect(window.location.assign).toMatchSnapshot();
  submitSearch("foo");
  expect(window.location.assign).toMatchSnapshot();
});
