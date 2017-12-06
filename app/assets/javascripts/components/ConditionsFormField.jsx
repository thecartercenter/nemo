class ConditionsFormField extends React.Component {

  constructor(props) {
    super();
    this.getFieldData = this.getFieldData.bind(this);
    this.updateFieldData = this.updateFieldData.bind(this);
    this.formatRefQingOptions = this.formatRefQingOptions.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildValueProps = this.buildValueProps.bind(this);
    this.state = props;
  }

  updateFieldData(refQingId) {
    this.getFieldData(refQingId);
  }

  getFieldData(refQingId) {
    ELMO.app.loading(true);
    var self = this;
    var url = this.buildUrl(refQingId);
    $.ajax(url)
      .done(function(response) {
          self.setState(response);
        })
        .fail(function(jqXHR, exception){
          console.log(exception);
        })
        .always(function() {
          ELMO.app.loading(false);
        });
  }

  buildUrl(refQingId) {
    var url = `${ELMO.app.url_builder.build('questionings', 'condition-form')}?condition_id=${this.state.id}&ref_qing_id=${refQingId}&form_id=${this.state.form_id}`
    if (this.state.questioning_id) {
      url += '&questioning_id=' + this.state.questioning_id;
    }
    return url;
  }

  formatRefQingOptions(reference_qing_options) {
    return reference_qing_options.map(function(o){
      return {id: o.id, name: `${o.full_dotted_rank}. ${o.code}`, key: o.id};
    });
  }

  buildValueProps(name_prefix, id_prefix) {
    if (this.state.option_node != null) {
      return {
        type: "cascading_select",
        name: `${name_prefix}[option_node_ids][]`,
        for: `${id_prefix}_value`, //not a mistake; the for is for value; the others are for selects
        id: `${id_prefix}_option_node_ids_`,
        key: `${id_prefix}_option_node_ids_`,
        option_node: this.state.option_node,
        label: I18n.t('activerecord.attributes.condition.value')
      }
    } else {
      return {
        type: "text",
        name: `${name_prefix}[value]`,
        for: `${id_prefix}_value`,
        id: `${id_prefix}_value`,
        key: `${id_prefix}_value`,
        value: this.state.value ? this.state.value : "",
        label: I18n.t('activerecord.attributes.condition.value')
      }
    }
  }

  render() {
    let name_prefix = 'questioning[display_conditions_attributes][]';
    let id_prefix = 'questioning_display_conditions_attributes';
    let condition_field_props = {
      type: "hidden",
      name: `${name_prefix}[id]`,
      id: `${id_prefix}_id`,
      key: `${id_prefix}_id`,
      value: this.state.id ? this.state.id : ""
    };
    let ref_qing_field_props = {
      type: "select",
      name: `${name_prefix}[ref_qing_id]`,
      id: `${id_prefix}_ref_qing_id`,
      for: `${id_prefix}_ref_qing_id`,
      key: `${id_prefix}_ref_qing_id`,
      value: this.state.ref_qing_id ? this.state.ref_qing_id : "",
      label: I18n.t('activerecord.attributes.condition.ref_qing_id'),
      options: this.formatRefQingOptions(this.state.refable_qings),
      changeFunc: this.updateFieldData
    };
    let operator_field_props = {
      type: "select",
      name: `${name_prefix}[op]`,
      id: `${id_prefix}_op`,
      for: `${id_prefix}_op`,
      key: `${id_prefix}_op`,
      value: this.state.op ? this.state.op : "",
      label: I18n.t('activerecord.attributes.condition.op'),
      options: this.state.operator_options
    };
    let value_field_props = this.buildValueProps(name_prefix, id_prefix);
    return (
      <div className="form_field">
        <div className="label_and_control">
          <label className="main">Condition</label>
          <div className="control">
            <input {...condition_field_props}/>
            <FormField {...ref_qing_field_props} />
            <FormField {...operator_field_props} />
            <FormField {...value_field_props} />
          </div>
        </div>
      </div>
    );
  }
}
