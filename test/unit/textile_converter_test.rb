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
  
  test "service desk" do
    service_desk_html = "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><style>p { margin-top:0px; margin-bottom:0px}</style><p><div><span><span><span><span>Sir,</span></span></span></span></div><span><span><span><span><span></span></span></span></span></span><br><span><span><span><span><span></span></span></span></span></span><br><span><span><span><span><span>&nbsp;I have submitted a ticket to verify. </span><br></span><br></span><br><span><span><span>Please let us know if we can be of any further assistance.<br><span><span><span><font color=\"#ff0000\"><strong><img src=\"cid:Image0\" width=\"373\" height=\"48\"><span style=\"FONT-FAMILY: \"><shapetype id=\"_x0000_t75\" stroked=\"f\" filled=\"f\" path=\"m@4@5l@4@11@9@11@9@5xe\" o:preferrelative=\"t\" o:spt=\"75\" coordsize=\"21600,21600\" /><font color=\"#000000\">&nbsp;<stroke joinstyle=\"miter\" /></font><formulas /><f eqn=\"if lineDrawn pixelLineWidth 0\" /><f eqn=\"sum @0 1 0\" /><f eqn=\"sum 0 0 @1\" /><f eqn=\"prod @2 1 2\" /><f eqn=\"prod @3 21600 pixelWidth\" /><f eqn=\"prod @3 21600 pixelHeight\" /><f eqn=\"sum @0 0 1\" /><f eqn=\"prod @6 1 2\" /><f eqn=\"prod @7 21600 pixelWidth\" /><f eqn=\"sum @8 21600 0\" /><f eqn=\"prod @7 21600 pixelHeight\" /><f eqn=\"sum @10 21600 0\" /></formulas><path o:connecttype=\"rect\" gradientshapeok=\"t\" o:extrusionok=\"f\" /><lock aspectratio=\"t\" v:ext=\"edit\" /></shapetype><shape style=\"WIDTH: 97.5pt; HEIGHT: 42.75pt\" id=\"Picture_x0020_1\" alt=\"Description: Description: C:\\Documents and Settings\UDXW140\Local Settings\\Temporary Internet Files\\Content.Word\\TL_Pacesetter_Logo_Final_RGB.JPG\" type=\"#_x0000_t75\" o:spid=\"_x0000_i1025\" /><imagedata o:href=\"cid:Image1\" src=\"file:///C:\\Users\\urxv003\\AppData\\Local\\Temp\\msohtmlclip1\\01\\clip_image001.jpg\" /></imagedata></shape></span></strong></font></span><br><font color=\"#000000\"><span><strong>First Level Support Person</strong></span><br></font><span><strong><font color=\"#000000\">E-Commerce Specialist / Our Company</font></strong></span><br><span><strong>Phone</strong> 555 555-5555 <font color=\"#cc6600\">/</font> 555 555-5555 <font color=\"#cc6600\">/</font> Ext 5555</span></span><br><span><span></span><span><u><span style=\"mso-fareast-font-family: Calibri; mso-fareast-theme-font: minor-latin\"><a href=\"http://www.example.com\"><font color=\"#cc6600\" size=\"3\" face=\"Times New Roman\">www.example.com</font></a></span></u></span></span></span></span></span></span></span></span><br><span><span><span><span><span><span><span><span><span><span><span><strong><div><span style=\"FONT-WEIGHT: normal\"><strong></strong></span></div></p>"
    service_desk_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(service_desk_html).to_wiki
    assert_equal "\nSir,\n\n&#160;I have submitted a ticket to verify.\n\nPlease let us know if we can be of any further assistance.\n!cid:Image0!*&#160;*\n*First Level Support Person*\n*E&#45;Commerce Specialist / Our Company*\n*Phone* 555 555&#45;5555 / 555 555&#45;5555 / Ext 5555\n+www.example.com+",
                 service_desk_text
  end
  
  test "consolidate formatting" do
    #bold_signature_html = "<body lang=EN-US link=blue vlink=purple><div class=WordSection1><p class=MsoNormal>test<o:p></o:p></p><p class=MsoNormal><o:p>&nbsp;</o:p></p><table class=MsoNormalTable border=0 cellpadding=0><tr><td style='padding:.75pt .75pt .75pt .75pt'><p class=MsoNormal><img width=481 height=54 id=\"Picture_x0020_4\" src=\"cid:image001.gif@01CF9AF6.3484E270\"><span style='font-size:12.0pt'><o:p></o:p></span></p></td></tr><tr><td style='padding:.75pt .75pt .75pt 3.75pt'><p class=MsoNormal style='line-height:115%'><b><span style='font-size:12.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:#CD3529'>Todd Hambley<o:p></o:p></span></b></p><p class=MsoNormal style='line-height:115%'><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Manager of Systems Integration </span></b><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:#CD3529;letter-spacing:-.15pt'>/</span></b><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>&nbsp; Travel Leaders Corporate<o:p></o:p></span></b></p><p class=MsoNormal style='line-height:115%'><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Direct:</span></b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>&nbsp; 201.210.7859&nbsp; </span><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:#CD3529;letter-spacing:-.15pt'>/</span><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>&nbsp; <b>Cell:</b> 616.844.8705&nbsp; </span><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:#CD3529;letter-spacing:-.15pt'>/</span><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>&nbsp; <b>Alternate:</b> 888.963.7295 <b>Ext:</b> 6259<o:p></o:p></span></p><p class=MsoNormal style='line-height:115%'><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'><a href=\"http://www.travelleaderscorp.com/\"><span style='color:#DB7F31'>www.travelleaderscorp.com</span></a><o:p></o:p></span></p><p class=MsoNormal style='line-height:115%'><a href=\"http://www.facebook.com/pages/Travel-Leaders-Corporate-LLC/205141879498715\" target=\"_blank\"><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:blue;letter-spacing:-.15pt;text-decoration:none'><img border=0 width=32 height=32 id=\"_x0000_i1026\" src=\"cid:image002.gif@01CF9AF6.3484E270\" alt=\"Like us on Facebook\"></span></a><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>&nbsp;</span><a href=\"http://twitter.com/#!/TLCorporate\" target=\"_blank\"><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:blue;letter-spacing:-.15pt;text-decoration:none'><img border=0 width=32 height=32 id=\"_x0000_i1025\" src=\"cid:image003.gif@01CF9AF6.3484E270\" alt=\"Follow Us on Twitter\"></span></a><span style='font-size:12.0pt;line-height:115%;font-family:\"Times New Roman\",\"serif\";color:blue'><o:p></o:p></span></p><p class=MsoNormal><span style='font-size:12.0pt'><o:p>&nbsp;</o:p></span></p></td></tr></table><p class=MsoNormal>&nbsp;<o:p></o:p></p><p class=MsoNormal><o:p>&nbsp;</o:p></p></div></body>"
    bold_signature_html = "<p class=MsoNormal style='line-height:115%'><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>Manager of Systems Integration </span></b><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:#CD3529;letter-spacing:-.15pt'>/</span></b><b><span style='font-size:10.0pt;line-height:115%;font-family:\"Arial\",\"sans-serif\";color:black;letter-spacing:-.15pt'>&nbsp; Travel Leaders Corporate<o:p></o:p></span></b></p>"
    bold_signature_text = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter.new(bold_signature_html).to_wiki
    assert_equal "*%{color:black}Manager of Systems Integration%* *%{color:#CD3529}/%*<notextile></notextile>*%{color:black}&#160; Travel Leaders Corporate%*",
                 bold_signature_text
  end
end
