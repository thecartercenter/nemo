// Pads strings to the left.
String.prototype.lpad = function (pad_str, length) {
  let str = this;
  while (str.length < length) str = pad_str + str;
  return str;
};

// Pads strings to the right.
String.prototype.rpad = function (pad_str, length) {
  let str = this;
  while (str.length < length) str += pad_str;
  return str;
};

// Strips HTML from string.
String.prototype.strip_html = function () {
  let value = '';
  try {
    // This is a known idiom for stripping html.
    value = $(`<p>${this}</p>`).text();
    if (value == '') {
      value = this;
    }
  } catch (err) {
    value = this;
  } finally {
    value = value || '[Null]';
  }
  return value;
};
