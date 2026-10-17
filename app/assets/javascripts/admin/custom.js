// Admin behavior for the recipe form. Plain event delegation, so it works
// with Turbo page changes and with ingredient rows added after load.
// Searchable dropdowns come from Administrate's own `select` Stimulus
// controller (data-controller="select"), which also attaches to new rows.
(function () {
  "use strict";

  // ---- Tabs -------------------------------------------------------------
  function showTab(form, paneId) {
    form.querySelectorAll("[data-admin-tab]").forEach(function (tab) {
      tab.classList.toggle("active", tab.dataset.adminTab === paneId);
    });
    form.querySelectorAll(".tab-pane").forEach(function (pane) {
      pane.classList.toggle("active", pane.id === paneId);
    });
  }

  // After a failed save, open the first tab that has an error in it.
  document.addEventListener("turbo:load", function () {
    var errored = document.querySelector(".tab-pane .field_with_errors");
    if (errored) showTab(errored.closest("form"), errored.closest(".tab-pane").id);
  });

  // ---- Ingredient rows ----------------------------------------------------
  function rows(container) {
    return container.querySelectorAll("[data-rows] > [data-row]");
  }

  function destroyBox(row) {
    return row.querySelector("input[type=checkbox][name$='[_destroy]']");
  }

  // Positions follow the on-screen order; rows marked for removal are skipped.
  function renumber(container) {
    var n = 1;
    rows(container).forEach(function (row) {
      var box = destroyBox(row);
      if (box && box.checked) return;
      row.querySelector("[data-position]").value = n++;
    });
  }

  document.addEventListener("click", function (event) {
    var tab = event.target.closest("[data-admin-tab]");
    if (tab) {
      event.preventDefault();
      showTab(tab.closest("form"), tab.dataset.adminTab);
      return;
    }

    var add = event.target.closest("[data-add-row]");
    if (add) {
      var container = add.closest("[data-recipe-ingredients]");
      var template = container.querySelector("template[data-row-template]");
      var html = template.innerHTML.replace(/NEW_RECORD/g, String(Date.now()));
      container.querySelector("[data-rows]").insertAdjacentHTML("beforeend", html);
      renumber(container);
    }
  });

  document.addEventListener("change", function (event) {
    var row = event.target.closest("[data-row]");
    if (row && event.target === destroyBox(row)) {
      row.classList.toggle("is-removed", event.target.checked);
      renumber(row.closest("[data-recipe-ingredients]"));
    }
  });

  // Enter in an ingredient field shouldn't submit the whole recipe.
  document.addEventListener("keydown", function (event) {
    if (event.key === "Enter" && event.target.tagName === "INPUT" &&
        event.target.closest("[data-recipe-ingredients]")) {
      event.preventDefault();
    }
  });

  // Drag rows by their handle to reorder.
  var dragged = null;

  document.addEventListener("mousedown", function (event) {
    var handle = event.target.closest(".recipe-ingredient__handle");
    if (handle) handle.closest("[data-row]").setAttribute("draggable", "true");
  });

  document.addEventListener("dragstart", function (event) {
    var row = event.target.closest && event.target.closest("[data-row][draggable]");
    if (!row) return;
    dragged = row;
    row.classList.add("is-dragging");
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", "");
  });

  document.addEventListener("dragover", function (event) {
    if (!dragged) return;
    var over = event.target.closest && event.target.closest("[data-row]");
    if (!over || over === dragged || over.parentNode !== dragged.parentNode) return;
    event.preventDefault();
    var box = over.getBoundingClientRect();
    var after = event.clientY > box.top + box.height / 2;
    over.parentNode.insertBefore(dragged, after ? over.nextSibling : over);
  });

  document.addEventListener("drop", function (event) {
    if (dragged) event.preventDefault();
  });

  document.addEventListener("dragend", function () {
    if (!dragged) return;
    var container = dragged.closest("[data-recipe-ingredients]");
    dragged.classList.remove("is-dragging");
    dragged.removeAttribute("draggable");
    dragged = null;
    renumber(container);
  });

  // ---- Trix -------------------------------------------------------------
  // Allow relative links (/recipes/...) as well as full URLs.
  document.addEventListener("trix-initialize", function (event) {
    var input = event.target.toolbarElement.querySelector("input[name=href]");
    if (input) {
      input.type = "text";
      input.pattern = "(https?://|/).+";
    }
  });
})();
