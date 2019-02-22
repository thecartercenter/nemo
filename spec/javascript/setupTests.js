import Enzyme from "enzyme";
import Adapter from "enzyme-adapter-react-16";
import I18n from "i18n-js";

// Stub out jquery.
// eslint-disable-next-line no-undef
window.$ = () => {};

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
