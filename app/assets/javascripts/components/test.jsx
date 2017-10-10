/* This is a test component to demo react-rails setup.
* To render: <%= react_component("Test", {content: "Hello World"}) %>
*/

class Test extends React.Component {
  render() {
    return <h1>{this.props.content}</h1>
  }
}
