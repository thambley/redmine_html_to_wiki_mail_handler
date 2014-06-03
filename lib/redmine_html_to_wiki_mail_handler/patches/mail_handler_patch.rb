# encoding: utf-8
# use require_dependency if you plan to utilize development mode
require 'mail_handler'

module RedmineHtmlToWikiMailHandler
  module Patches
    module MailHandlerPatch
      extend ActiveSupport::Concern
      
      included do # :nodoc:
        unloadable
        
        #alias method chain?
        #after_create :issue_created_journal
        alias_method_chain :plain_text_body, :to_wiki
      end
      
      # Returns the text/plain part of the email
      # If not found (eg. HTML-only email), returns the body with tags removed
      def plain_text_body_with_to_wiki
        logger.info  "override plain_text_body"
        return @plain_text_body unless @plain_text_body.nil?
        logger.info  "@plain_text_body not found"

        parts = if (text_parts = email.all_parts.select {|p| p.mime_type == 'text/plain'}).present?
                  logger.info  "parts = text_parts"
                  text_parts
                elsif (html_parts = email.all_parts.select {|p| p.mime_type == 'text/html'}).present?
                  logger.info  "parts = html_parts"
                  html_parts
                else
                  logger.info  "parts = [email]"
                  [email]
                end

        parts.reject! do |part|
          part.header[:content_disposition].try(:disposition_type) == 'attachment'
        end

        @plain_text_body = parts.map do |p|
          body_charset = p.charset.respond_to?(:force_encoding) ?
                           Mail::RubyVer.pick_encoding(p.charset).to_s : p.charset
          Redmine::CodesetUtil.to_utf8(p.body.decoded, body_charset)
        end.join("\r\n")

        # strip html tags and remove doctype directive
        if parts.any? {|p| p.mime_type == 'text/html'}
          logger.info  "to_wiki"
          logger.info "plain_text_body: #{@plain_text_body}"
          @plain_text_body = ::RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting.formatter.new(@plain_text_body).to_wiki
          #@plain_text_body = strip_tags(@plain_text_body.strip)
          #@plain_text_body.sub! %r{^<!DOCTYPE .*$}, ''
          logger.info "(after to_wiki) plain_text_body: #{@plain_text_body}"
        end

        @plain_text_body
      end
      
    end
  end
end

unless MailHandler.included_modules.include? RedmineHtmlToWikiMailHandler::Patches::MailHandlerPatch
  MailHandler.send(:include, RedmineHtmlToWikiMailHandler::Patches::MailHandlerPatch)
end