class ConditionsFormField extends React.Component {

  constructor() {
    super();

    this.name_prefix = "questioning[condition_attributes]"
    this.for_prefix = "questioning_condition_attributes"
    this.getFieldData = this.getFieldData.bind(this)

  }

  getFieldData() {
    console.log("get field data!")
    //fake data first
    let reference_qing_options = [["1", "One"], ["2", "Two"], ["3", "Three"]]
    let reference_qing_data = {for: "questioning_condition_attributes_ref_qing_id", label: "question", name: "questioning[condition_attributes][ref_qing_id]", id: "questioning_condition_attributes_ref_qing_id", type: "select", options: reference_qing_options}

    let operator_options = [["A", "Ey"], ["B", "Bee"], ["C", "See"]]
    let operator_data = {for: "questioning_condition_attributes_op", label: "operator", name: "questioning[condition_attributes][op]", id: "questioning_condition_attributes_op", type: "select", options: operator_options }

    let value_data = {for: "questioning_condition_attributes_value" , label: "Value", name: "questioning[condition_attributes][value]" , id: "questioning_condition_attributes_value" , type: "text"}

    return {reference_qing_field: reference_qing_data, operator_field: operator_data, value_field: value_data}
  }

  componentDidMount() {
    this.state = this.getFieldData()
  }

  render() {

    let rq = this.state ? this.state.reference_qing_field : this.props.reference_qing_field
    let ref_qing_form_field = <FormField for={rq.for} label={rq.label} type={rq.type} options={rq.options} id={rq.id} key={rq.id} changeFunc={() => alert("HI") }/>
    let o = this.state ? this.state.operator_field : this.props.operator_field
    let operator_form_field = <FormField for={o.for} label={o.label} type={o.type} options={o.options} id={o.id} key={o.id} changeFunc={() => alert("HI") }/>
    let v = this.props.value_field
    let value_form_field =  <FormField for={v.for} label={v.label} type={v.type} id={v.id} key={v.id}/>
    let fields = [ref_qing_form_field, operator_form_field, value_form_field]
    return <div>{fields}</div>

  }
}
