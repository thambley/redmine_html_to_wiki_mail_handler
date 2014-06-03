#require 'redmine'
require 'redmine_html_to_wiki_mail_handler'

Redmine::Plugin.register :redmine_html_to_wiki_mail_handler do
  name 'Redmine HTML to wiki mail handler plugin'
  author 'Todd Hambley'
  description 'Redmine HTML to wiki mail handler'
  version '0.0.10'
  requires_redmine :version_or_higher => '2.4.0'
end