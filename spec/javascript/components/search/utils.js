export const formFilterProps = {
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
  originalFormIds: [
  ],
};

export const advancedSearchProps = {
  advancedSearchText: 'query',
};

export const allFilterProps = {
  ...formFilterProps,
  ...advancedSearchProps,
};
