/**
 * Stubbed Bootstrap components seem to cause these warnings
 * when `mount`ed with Enzyme (though react-test-renderer is fine).
 */
// eslint-disable-next-line max-len
export const STUB_COMPONENT_WARNINGS = /Warning: (<.*> is using incorrect casing|The tag <.*> is unrecognized in this browser|React does not recognize the `.*` prop on a DOM element)/;

// eslint-disable-next-line no-console
const originalConsoleError = console.error;

export function suppressErrors(matcher = /^$/) {
  // eslint-disable-next-line no-console
  console.error = (...messages) => {
    if (messages[0].match(matcher)) {
      return;
    }

    originalConsoleError(...messages);
  };
}

export function unsuppressAllErrors() {
  // eslint-disable-next-line no-console
  console.error = originalConsoleError;
}
