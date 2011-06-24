function lookup_places(query, div_id) {
  // send updater request
  new Ajax.Updater(div_id, '/place_lookups/suggest', {
    parameters: { query: query }, 
    method: "get"
  });
}