import ConditionModel from './model';

describe('currTextValue', () => {
  it('computes currTextValue (basic value)', () => {
    const store = new ConditionModel({ value: 'foo' });
    expect(store.currTextValue).toMatchSnapshot();
  });

  it('computes currTextValue (cascading select with nothing selected)', () => {
    const store = new ConditionModel({ value: 'unused', optionSetId: 'something' });
    expect(store.currTextValue).toMatchSnapshot();
  });

  it('computes currTextValue (cascading select with something selected)', () => {
    const store = new ConditionModel({
      optionSetId: 'something',
      levels: [
        {
          selected: '1',
          options: [
            { id: '1', name: 'One' },
          ],
        },
      ],
    });
    expect(store.currTextValue).toMatchSnapshot();
  });
});

describe('rightQingOptions reaction', () => {
  it('is empty with no leftQingId', () => {
    const store = new ConditionModel({
      leftQingId: null,
    });
    expect(store.rightQingOptions).toMatchSnapshot();
  });

  it('filters out the correct qings when leftQing is text', () => {
    const store = new ConditionModel({
      leftQingId: '2',
      refableQings: [
        { id: '1', qtypeName: 'integer', textual: false, numeric: true },
        { id: '2', qtypeName: 'text', textual: true, numeric: false },
        { id: '3', qtypeName: 'text', textual: true, numeric: false },
        { id: '4', qtypeName: 'longtext', textual: true, numeric: false },
      ],
    });
    expect(store.rightQingOptions).toMatchSnapshot();
  });

  it('filters out the correct qings when leftQing is numeric', () => {
    const store = new ConditionModel({
      leftQingId: '1',
      refableQings: [
        { id: '1', qtypeName: 'integer', textual: false, numeric: true },
        { id: '2', qtypeName: 'text', textual: true, numeric: false },
        { id: '3', qtypeName: 'integer', textual: false, numeric: true },
        { id: '4', qtypeName: 'decimal', textual: false, numeric: true },
      ],
    });
    expect(store.rightQingOptions).toMatchSnapshot();
  });

  it('filters out the correct qings when leftQing is datetime', () => {
    const store = new ConditionModel({
      leftQingId: '1',
      refableQings: [
        { id: '1', qtypeName: 'datetime', textual: false, numeric: false },
        { id: '2', qtypeName: 'datetime', textual: false, numeric: false },
        { id: '3', qtypeName: 'integer', textual: false, numeric: true },
        { id: '4', qtypeName: 'datetime', textual: false, numeric: false },
      ],
    });
    expect(store.rightQingOptions).toMatchSnapshot();
  });

  it('filters out the correct qings when leftQing is select_one', () => {
    const store = new ConditionModel({
      leftQingId: '1',
      refableQings: [
        { id: '1', qtypeName: 'select_one', textual: false, numeric: false, optionSetId: '1' },
        { id: '2', qtypeName: 'select_one', textual: false, numeric: false, optionSetId: '1' },
        { id: '3', qtypeName: 'select_one', textual: false, numeric: false, optionSetId: '2' },
        { id: '4', qtypeName: 'select_one', textual: false, numeric: false, optionSetId: '1' },
        { id: '5', qtypeName: 'integer', textual: false, numeric: true },
      ],
    });
    expect(store.rightQingOptions).toMatchSnapshot();
  });

  it('filters out all qings when leftQing is select_multiple', () => {
    const store = new ConditionModel({
      leftQingId: '1',
      refableQings: [
        { id: '1', qtypeName: 'select_multiple', textual: false, numeric: false, optionSetId: '1' },
        { id: '2', qtypeName: 'select_multiple', textual: false, numeric: false, optionSetId: '1' },
        { id: '3', qtypeName: 'integer', textual: false, numeric: true },
      ],
    });
    expect(store.rightQingOptions).toMatchSnapshot();
  });
});
