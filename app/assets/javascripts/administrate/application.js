//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require selectize
//= require trix
//= require cocoon
//= require_tree .

addEventListener("trix-initialize", event => {
  const { toolbarElement } = event.target
  const inputElement = toolbarElement.querySelector("input[name=href]")
  inputElement.type = "text"
  inputElement.pattern = "(https?://|/).+"
})

// Don't submit the recipe form when Enter is pressed in an ingredient note.
$(document).on("keyup keypress", ".ingredient-note", function(e) {
  if ((e.keyCode || e.which) === 13) {
    e.preventDefault();
    return false;
  }
});

// Turn the selects in a newly added ingredient row into searchable dropdowns.
$(document).on("cocoon:after-insert", function(e, insertedItem) {
  $(insertedItem).find(".field-unit--belongs-to select, .field-unit--select select").selectize({});
});
