class ConditionsFormField extends React.Component {

  constructor() {
    super();

    this.name_prefix = "questioning[condition_attributes]"
    this.for_prefix = "questioning_condition_attributes"
  }

  componentDidMount() {
    this.state =
    {
      reference_qing_field : this.props.reference_qing_field,
      operator_field: this.props.operator_field,
      value_field: this.props.value_field
    }
  }

  render() {
    let rq = this.props.reference_qing_field
    let ref_qing_form_field = <FormField for={rq.for} label={rq.label} type={rq.type} options={rq.options} id={rq.id} key={rq.id}/>
    let o = this.props.operator_field
    let operator_form_field = <FormField for={o.for} label={o.label} type={o.type} options={o.options} id={o.id} key={o.id}/>
    let v = this.props.value_field
    let value_form_field =  <FormField for={v.for} label={v.label} type={v.type} id={v.id} key={v.id}/>
    let fields = [ref_qing_form_field, operator_form_field, value_form_field]
    return <div>{fields}</div>

  }
}
