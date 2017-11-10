class FormField extends React.Component {
  render() {
    var control = <input className="text form-control" key="input" type="text" name="questioning[condition_attributes][value]" id="questioning_condition_attributes_value" defaultValue={this.props.value} />
    if (this.props.type === "select") {
      control = <FormSelect value={this.props.value} key="input" name={this.props.name} id={this.props.id} options={this.props.options} changeFunc={this.props.changeFunc} />
    }
    return (
      <div className="field">
        <label htmlFor={this.props.for} key={this.props.for}> {this.props.label} </label>
        {control}
      </div>

    )
  }
}
