//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require selectize
//= require moment
//= require datetime_picker
//= require trix
//= require cocoon
//= require_tree .

addEventListener("trix-initialize", event => {
  const { toolbarElement } = event.target
  const inputElement = toolbarElement.querySelector("input[name=href]")
  inputElement.type = "text"
  inputElement.pattern = "(https?://|/).+"
})

$(".ingredient-note").on("keyup keypress", function(e) {
  var keyCode = e.keyCode || e.which;
  if (keyCode === 13) { 
    e.preventDefault();
    return false;
  }
});

$(document).on('click', '.field-unit--nested-has-many .add_fields', () => {
  $(".field-unit--belongs-to select").each(function initializeSelectize(index, element) {
    var $element = $(element);
    $element.selectize({});
  });
  $(".field-unit--select select").each(function initializeSelectize(index, element) {
    var $element = $(element);
    $element.selectize({});
  });
});

