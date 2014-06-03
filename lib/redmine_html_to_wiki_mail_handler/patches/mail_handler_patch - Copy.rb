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
      
      def to_wiki(html, blocks)

        # remove any \n or \r chars, remove all spaces after <br> tags, 
        # change out \240 (&nbsp;) with space, sqeeze all multiple spaces
        html = html.gsub(/[\n\r]/, '').gsub(/<br>[ ]+/, "<br>").gsub(/\\240/, ' ').squeeze(' ').strip
        
        logger.info "plain_text_body: #{html}"
        

        # load html fragment
        doc = Nokogiri::HTML.fragment(html) do |config|
          config.noblanks
        end

        # Get rid of superfluous whitespace in the source
        doc.xpath('.//text()').each{ |t| t.content=t.text.gsub(/\s+/,' ') }
        # Process blocks, adding pre, post, whitespace entires
        blocks.each { |b|
          doc.css(b["tags"].join(',')).each { |n|
            n.before(b["pre"])
            n.after(b["post"])
          }
        }

        # Remove all style content
        doc.xpath('.//style').each{ |n| n.remove }
        
        logger.info "plain_text_body: #{doc.text}"

        doc.text.gsub(/\n[ ]+/, "\n").strip << "\n" 
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
          blocks = [{ "tags"=> %w[p ul li div address], "attr"=>"", "pre"=>"","post"=>"\n\n","ws"=>"" },
                { "tags"=> %w[br], "attr"=>"", "pre"=>"","post"=>"\n","ws"=> "" },
                { "tags"=> %w[hr], "attr"=>"", "pre"=>"","post"=>"\n#{'-'*70}\n","ws"=>""},
                { "tags"=> %w[b strong], "attr"=>"", "pre"=>"*","post"=>"*","ws"=>""},
                { "tags"=> %w[i em], "attr"=>"", "pre"=>"_","post"=>"_","ws"=>""},
                { "tags"=> %w[u], "attr"=>"", "pre"=>"+","post"=>"+","ws"=>""},
                { "tags"=> %w[strike], "attr"=>"", "pre"=>"-","post"=>"-","ws"=>""},
                { "tags"=> %w[sub], "attr"=>"", "pre"=>"~","post"=>"~","ws"=>""},
                { "tags"=> %w[sup], "attr"=>"", "pre"=>"^","post"=>"^","ws"=>""},
                { "tags"=> %w[h1 h2 h3 h4 h5 h6 h7 h8 h9], "attr"=>"", "pre"=>"","post"=>"\n\n","ws"=>"" },
                { "tags"=> %w[h1], "attr"=>"", "pre"=>"h1. ","post"=>"","ws"=>""},
                { "tags"=> %w[h2], "attr"=>"", "pre"=>"h2. ","post"=>"","ws"=>""},
                { "tags"=> %w[h3], "attr"=>"", "pre"=>"h3. ","post"=>"","ws"=>""},
                { "tags"=> %w[h4], "attr"=>"", "pre"=>"h4. ","post"=>"","ws"=>""},
                { "tags"=> %w[h5], "attr"=>"", "pre"=>"h5. ","post"=>"","ws"=>""},
                { "tags"=> %w[h6], "attr"=>"", "pre"=>"h6. ","post"=>"","ws"=>""},
                { "tags"=> %w[h7], "attr"=>"", "pre"=>"h7. ","post"=>"","ws"=>""},
                { "tags"=> %w[h8], "attr"=>"", "pre"=>"h8. ","post"=>"","ws"=>""},
                { "tags"=> %w[h9], "attr"=>"", "pre"=>"h9. ","post"=>"","ws"=>""},
          ]
          @plain_text_body = to_wiki(@plain_text_body, blocks)
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