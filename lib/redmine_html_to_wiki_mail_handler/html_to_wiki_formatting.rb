module RedmineHtmlToWikiMailHandler
  module HtmlToWikiFormatting

    @@formatters = {}

    class << self
      def map
        yield self
      end

      def register(name, formatter, options={})
        name = name.to_s
        raise ArgumentError, "format name '#{name}' is already taken" if @@formatters[name]
        @@formatters[name] = {
          :formatter => formatter,
          :label => options[:label] || name.humanize
        }
      end

      def formatter
        formatter_for(Setting.text_formatting)
      end

      def formatter_for(name)
        entry = @@formatters[name.to_s]
        (entry && entry[:formatter]) || RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting::NullFormatter::Formatter
      end

      def format_names
        @@formatters.keys.map
      end

      def formats_for_select
        @@formatters.map {|name, options| [options[:label], name]}
      end

      def to_wiki(format, html, options = {})
        formatter_for(format).new(html).to_wiki
      end
    end

    # Default formatter module
    module NullFormatter
      class Formatter
        include ActionView::Helpers::SanitizeHelper
          
        def initialize(html)
          @workingcopy = html
        end

        def to_html(*args)
          @workingcopy = strip_tags(@workingcopy.strip)
          @workingcopy.sub! %r{^<!DOCTYPE .*$}, ''
          @workingcopy
        end
      end
    end
  end
end
