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
    assert_equal "h1. Give RedCloth a try&#33;",
                 header_text
  end
  
  test "bullet list 1" do
    list_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new("<ul>\n<li>an item</li>\n	<li>and another</li></ul>").to_wiki
    assert_equal "* an item\n* and another",
                 list_text
  end
  
  # more complicated conversions:
  
  test "paragraph with some formatting" do
    paragraph_html = "<p>A <strong>simple</strong> paragraph with<br />\na line break, some <em>emphasis</em> and a <a href=\"http://redcloth.org\">link</a></p>"
    paragraph_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(paragraph_html).to_wiki
    assert_equal "A *simple* paragraph with\na line break, some _emphasis_ and a \"link\":http://redcloth.org",
                 paragraph_text
  end
  
  test "lists" do
    list_html = "<ul>\n<li>an item</li>\n	<li>and another</li>\n</ul>\n<ol>\n	<li>one</li>\n	<li>two</li>\n</ol>"
    list_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(list_html).to_wiki
    assert_equal "* an item\n* and another\n\n# one\n# two",
                 list_text
  end
  
  test "service desk" do
    service_desk_html = "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
    service_desk_html << "<style>p { margin-top:0px; margin-bottom:0px}</style>"
    service_desk_html << "<p>"
    service_desk_html << "<div><span><span><span><span>Sir,</span></span></span></span></div>"
    service_desk_html << "<span><span><span><span><span></span></span></span></span></span><br>"
    service_desk_html << "<span><span><span><span><span></span></span></span></span></span><br>"
    service_desk_html << "<span><span>" #not matched
    service_desk_html << "<span><span><span>&nbsp;I have submitted a ticket to verify. </span><br></span><br></span><br>"
    service_desk_html << "<span><span><span>" #not matched
    service_desk_html << "Please let us know if we can be of any further assistance.<br>"
    service_desk_html << "</span></span></span>" #not matched
    service_desk_html << "</span></span>" #not matched
    service_desk_html << "</p>"
    service_desk_html.gsub!(/&nbsp;/,160.chr(Encoding::UTF_8))
    service_desk_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(service_desk_html).to_wiki
    assert_equal "\nSir,\n\n&nbsp;I have submitted a ticket to verify.\n\nPlease let us know if we can be of any further assistance.",
                 service_desk_text
  end
  
  test "consolidate formatting" do
    bold_signature_html = "<p class=MsoNormal style='line-height:115%'><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Manager of Systems </span></b><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:#CD3529;letter-spacing:-.15pt'>/</span></b><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>&nbsp; Company Corporate<o:p></o:p></span></b></p>"
    bold_signature_html.gsub!(/&nbsp;/,160.chr(Encoding::UTF_8))
    bold_signature_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(bold_signature_html).to_wiki
    assert_equal "*%{color:black}Manager of Systems%* *%{color:#CD3529}/%*&nbsp; *%{color:black}Company Corporate%*",
                 bold_signature_text
  end
  
  test "link with style" do
    link_html = "<a href=\"http://www.example.com/\"><span style='color:#3333FF'>www.example.com</span></a>"
    link_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(link_html).to_wiki
    assert_equal "www.example.com",
                 link_text
  end
  
  test "signature one" do
    signature_html  = "<p class=MsoNormal>"
    signature_html << "<b>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Business Person </span>"
    signature_html << "</b>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Tahoma\",\"sans-serif\";color:gray'>| </span>"
    signature_html << "<b>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Business Process Analyst </span>"
    signature_html << "</b>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Tahoma\",\"sans-serif\";color:gray'>&nbsp;| </span>"
    signature_html << "<b>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Corporate<o:p></o:p></span>"
    signature_html << "</b>"
    signature_html << "</p>"
    signature_html.gsub!(/&nbsp;/,160.chr(Encoding::UTF_8))
    signature_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(signature_html).to_wiki
    assert_equal "*%{color:black}Business Person%* %{color:gray}&#124;% *%{color:black}Business Process Analyst%*&nbsp; %{color:gray}&#124;% *%{color:black}Corporate%*",
                 signature_text
  end
  
  test "signature two" do
    signature_html  = "<p class=MsoNormal>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Phone: </span>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black'>555.555.5555</span>"
    signature_html << "<b>"
    signature_html << "<span style='font-size:12.0pt;font-family:\"Arial\",\"sans-serif\"'> </span>"
    signature_html << "</b>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>x5555 </span>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Tahoma\",\"sans-serif\";color:gray'>|</span>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'> Direct: 555.555.5555&nbsp;</span>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Tahoma\",\"sans-serif\";color:gray'>| </span>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Tahoma\",\"sans-serif\"'>"
    signature_html << "<a href=\"mailto:someone@example.com\">"
    signature_html << "<span style='color:blue'>someone@example.com</span>"
    signature_html << "</a>"
    signature_html << "</span>"
    signature_html << "<span style='font-size:10.0pt;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'><o:p></o:p></span>"
    signature_html << "</p>"
    signature_html.gsub!(/&nbsp;/,160.chr(Encoding::UTF_8))
    signature_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(signature_html).to_wiki
    assert_equal "%{color:black}Phone:% %{color:black}555.555.5555% %{color:black}x5555% %{color:gray}&#124;% %{color:black}Direct: 555.555.5555%&nbsp;<notextile></notextile>%{color:gray}&#124;% someone@example.com",
                 signature_text
  end
end
