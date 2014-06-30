require File.expand_path('../../test_helper', __FILE__)

class TextileConverterTest < ActiveSupport::TestCase
  #fixtures :html_strings

  test "simple bold text conversion" do
    simple_bold_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<b>test</b>").to_wiki
    assert_equal "*test*", simple_bold_text, "Expected *test*"
  end

end
