class FormSelect extends React.Component {
  render() {
    let options =
        [
          <option value="1" key="1">Bir</option>,
          <option value="2" key="2">Iki</option>,
          <option value="3" key="3">Uc</option>
        ]
    return <select className="form-control test-select">{options}</select>
  }
}
