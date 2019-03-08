import isEmpty from "lodash/isEmpty";

export function getUrlString(selectedFormIds) {
  const parts = [
    isEmpty(selectedFormIds) ? null : `form:(${selectedFormIds.join("|")})`,
  ].filter(Boolean);

  return parts.join(" ");
}

export function submitSearch(urlString) {
  window.location.assign(`?search=${urlString}`);
}
