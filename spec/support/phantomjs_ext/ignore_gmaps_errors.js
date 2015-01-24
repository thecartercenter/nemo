// Ignores weird Google Maps errors in PhantomJS.
window.onerror = function(message) {
  if (message == 'TypeError: Unable to delete property.') {
    console.log('Ignoring gmaps error');
    return false;
  } else {
    return true;
  }
};