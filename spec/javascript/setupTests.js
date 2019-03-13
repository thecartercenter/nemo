import Enzyme from "enzyme";
import Adapter from "enzyme-adapter-react-16";
import I18n from "i18n-js";

// Stub out jquery.
// eslint-disable-next-line no-undef
window.$ = () => {};

// Stub out navigation features (otherwise jsdom complains).
delete window.location;
window.location = {
  assign: jest.fn(),
};

// Stub out Bootstrap components.
[
  "Button",
  "ButtonToolbar",
  "OverlayTrigger",
  "Popover",
].forEach((name) => {
  jest.doMock(`react-bootstrap/lib/${name}`, () => name);
});

jest.mock("react-select2-wrapper/lib/components/Select2.full", () => "Select2");
jest.mock("react-select2-wrapper/css/select2.css", () => undefined);

// Provide translations.
// eslint-disable-next-line no-undef
window.I18n = I18n;

try {
  require("../../app/assets/javascripts/i18n/translations");
} catch (error) {
  // eslint-disable-next-line no-console
  console.error("Failed to find translations. Did you run `rails i18n:js:export` yet?");
}

// Initialize Enzyme.
Enzyme.configure({
  adapter: new Adapter(),
});
