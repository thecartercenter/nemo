import {
  getButtonHintString,
  getFormNameFromId,
  getFilterString,
  submitSearch,
} from "../../../../app/javascript/components/search/utils";
import {formFilterProps} from "./utils";

it("gets hints (0)", () => {
  const result = getButtonHintString([]);
  expect(result).toMatchSnapshot();
});

it("gets hints (small number)", () => {
  const result = getButtonHintString(["one"]);
  expect(result).toMatchSnapshot();
});

it("gets hints (too many)", () => {
  const result = getButtonHintString(["one", "two", "three"]);
  expect(result).toMatchSnapshot();
});

it("gets form name (found)", () => {
  const result = getFormNameFromId([{id: "1", name: "One"}], "1");
  expect(result).toMatchSnapshot();
});

it("gets form name (not found)", () => {
  const result = getFormNameFromId([], "1");
  expect(result).toMatchSnapshot();
});

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
