import {getFilterString, submitSearch} from "../../../../app/javascript/components/search/utils";

it("gets filter string (no filters)", () => {
  const result = getFilterString([]);
  expect(result).toMatchSnapshot();
});

it("gets filter string (all filters)", () => {
  const result = getFilterString(["1", "2"]);
  expect(result).toMatchSnapshot();
});

it("submits searches", () => {
  expect(window.location.assign).toMatchSnapshot();
  submitSearch("foo");
  expect(window.location.assign).toMatchSnapshot();
});
