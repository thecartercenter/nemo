import isEmpty from "lodash/isEmpty";

/**
 * Stringified controller_name from Rails.
 */
export const CONTROLLER_NAME = {
  RESPONSES: "\"responses\"",
};

/**
 * Given all of the different filter states,
 * return a stringified version for the backend.
 */
export function getFilterString(selectedFormIds) {
  const parts = [
    isEmpty(selectedFormIds) ? null : `form:(${selectedFormIds.join("|")})`,
  ].filter(Boolean);

  return parts.join(" ");
}

/**
 * Reload the page with the given search.
 */
export function submitSearch(filterString) {
  window.location.assign(`?search=${encodeURIComponent(filterString)}`);
}
