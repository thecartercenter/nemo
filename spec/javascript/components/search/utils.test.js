import {getUrlString, submitSearch} from "../../../../app/javascript/components/search/utils";

it("gets url strings (none)", () => {
  const result = getUrlString([]);
  expect(result).toMatchSnapshot();
});

it("gets url strings (all)", () => {
  const result = getUrlString(["1", "2"]);
  expect(result).toMatchSnapshot();
});

it("submits searches", () => {
  expect(window.location.assign).toMatchSnapshot();
  submitSearch("foo");
  expect(window.location.assign).toMatchSnapshot();
});
