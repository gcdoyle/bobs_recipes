module ApplicationHelper
  HIDDEN_CATEGORY = "chris"

  # A header link that is marked current when its section is showing.
  def nav_link(label, path, active: current_page?(path))
    link_to label, path, class: ["site-nav__link", ("is-active" if active)],
                         "aria-current": (active ? "page" : nil)
  end

  # The first letter a list is grouped under: A-Z, or "#" for anything else.
  def index_letter(name)
    letter = name.to_s.strip[0].to_s.upcase
    letter.match?(/[A-Z]/) ? letter : "#"
  end

  # Categories a visitor may browse to (the private one is left out).
  def public_categories(categories)
    categories.reject { |c| c.name.casecmp?(HIDDEN_CATEGORY) }.sort_by(&:name)
  end
end
