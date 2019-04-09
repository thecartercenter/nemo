import FiltersModel from '../../../../app/javascript/components/search/FiltersModel';

export const filtersStore = Object.assign(new FiltersModel(), {
  allForms: [
    {
      id: '1',
      name: 'One',
    },
    {
      id: '2',
      name: 'Two',
    },
    {
      id: '3',
      name: "Q\"uo'te`s",
    },
  ],
  selectedFormIds: [
    '2',
  ],
  advancedSearchText: 'query',
});
