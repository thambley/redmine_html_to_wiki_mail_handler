require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting'
require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting/simple_html/formatter'
require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting/textile/formatter'
#require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting/markdown/formatter'
 
RedmineApp::Application.config.after_initialize do
  require_dependency 'redmine_html_to_wiki_mail_handler/patches/mail_handler_patch'
end


RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting.map do |format|
  format.register :simple_html, RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::SimpleHtml::Formatter
  format.register :textile, RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter
  #if Object.const_defined?(:Redcarpet)
  #  format.register :markdown, RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Markdown::Formatter, :label => 'Markdown (experimental)'
  #end
end