class FormSelect extends React.Component {
  render() {
    let options = []
    if (this.props.include_blank !== false) {
      options.push(<option value="" key="blank">{this.props.prompt || ""}</option>);
    }
    let full_options = options.concat(this.props.options.map((o) =>
      {return <option value={o.id} key={o.id}>{o.name}</option>}))
    let props = {
      className : "form-control",
      name : this.props.name,
      id: this.props.id,
      key: this.props.id,
      defaultValue: this.props.value
    }
    if (this.props.changeFunc) {
      props["onChange"] = (e) => this.props.changeFunc(e.target.value)
    }
    return <select {...props} >{full_options}</select>
  }
}
