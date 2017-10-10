class FormSelect extends React.Component {
  render() {
    let options = this.props.options.map((o) => {return <option value={o.value} key={o.value}>{o.display}</option>}) 
    return <select className="form-control test-select">{options}</select>
  }
}
