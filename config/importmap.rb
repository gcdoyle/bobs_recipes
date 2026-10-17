# Pin npm packages by running ./bin/importmap

pin "application"
pin "bootstrap", to: "bootstrap.esm.min.js" # Bootstrap 5.3.8 (vendor/javascript)
pin "@popperjs/core", to: "@popperjs--core.js" # Popper 2.11.8, needed by Bootstrap dropdowns and tooltips
