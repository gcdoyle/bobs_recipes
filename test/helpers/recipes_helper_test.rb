require "test_helper"

class RecipesHelperTest < ActionView::TestCase
  test "formats quantities as kitchen fractions" do
    assert_equal "4 1/2", format_qty(BigDecimal("4.5"))
    assert_equal "1/8", format_qty(BigDecimal("0.13"))
    assert_equal "1/3", format_qty(BigDecimal("0.33"))
    assert_equal "2", format_qty(BigDecimal("2.0"))
    assert_equal "1.1", format_qty(BigDecimal("1.1"))
    assert_equal "", format_qty(nil)
  end
end
