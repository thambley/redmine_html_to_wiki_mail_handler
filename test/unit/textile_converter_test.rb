require File.expand_path('../../test_helper', __FILE__)

# http://en.wikipedia.org/wiki/Textile_(markup_language)

class TextileConverterTest < ActiveSupport::TestCase
  # entity conversion tests
  test "entity conversion" do
    entity_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<p>&#8221;</p>").to_wiki
    assert_equal "\"", 
                 entity_text
  end
  # character conversion tests
  test "character conversion" do
    character_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<p>" + 8221.chr(Encoding::UTF_8) + "</p>").to_wiki
    assert_equal "\"", 
                 character_text
  end
  # special character conversion tests
  test "special character conversion" do
    character_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<p>---</p><p>+_*</p>").to_wiki
    assert_equal "&#45;&#45;&#45;\n&#43;&#95;&#42;", 
                 character_text
  end
  
  # simple html to text conversion tests:
  
  test "bold text" do
    simple_bold_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<b>test</b>").to_wiki
    assert_equal "*test*", 
                 simple_bold_text,
                 "Expected: *test*"
  end
  
  test "header level 1" do
    header_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<h1>Give RedCloth a try!</h1>").to_wiki
    assert_equal "h1. Give RedCloth a try!",
                 header_text,
                 "Expected: h1. Give RedCloth a try!"
  end
  
  test "bullet list 1" do
    list_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<ul>\n<li>an item</li>\n	<li>and another</li></ul>").to_wiki
    assert_equal "* an item\n* and another",
                 list_text
  end
  
  # more complicated conversions:
  
  test "paragraph with some formatting" do
    paragraph_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<p>A <strong>simple</strong> paragraph with<br />\na line break, some <em>emphasis</em> and a <a href=\"http://redcloth.org\">link</a></p>").to_wiki
    assert_equal "A *simple* paragraph with\na line break, some _emphasis_ and a \"link\":http://redcloth.org",
                 paragraph_text
  end
  
  test "lists" do
    list_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<ul>\n<li>an item</li>\n	<li>and another</li>\n</ul>\n<ol>\n	<li>one</li>\n	<li>two</li>\n</ol>").to_wiki
    assert_equal "* an item\n* and another\n\n# one\n# two",
                 list_text
  end
end
