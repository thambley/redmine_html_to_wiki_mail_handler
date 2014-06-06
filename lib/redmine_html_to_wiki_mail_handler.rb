require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting'
require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting/simple_html/formatter'
require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting/textile/formatter'
#require 'redmine_html_to_wiki_mail_handler/html_to_wiki_formatting/markdown/formatter'

require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
 
if Rails::VERSION::MAJOR >= 3
   ActionDispatch::Callbacks.to_prepare do
     # use require_dependency if you plan to utilize development mode
     require 'redmine_html_to_wiki_mail_handler/patches/mail_handler_patch'
   end
else
  Dispatcher.to_prepare do
    # use require_dependency if you plan to utilize development mode
    require 'redmine_html_to_wiki_mail_handler/patches/mail_handler_patch'
  end
end


RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting.map do |format|
  format.register :simple_html, RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::SimpleHtml::Formatter
  format.register :textile, RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Textile::Formatter
  #if Object.const_defined?(:Redcarpet)
  #  format.register :markdown, RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::Markdown::Formatter, :label => 'Markdown (experimental)'
  #end
end