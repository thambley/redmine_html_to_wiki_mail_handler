require 'nokogiri'
require 'pp'

module RedmineHtmlToWikiMailHandler
  module HtmlToWikiFormatting
    module SimpleHtml
      class Formatter < String
  
        def initialize(html)
          super(html)
          @workingcopy = html
        end
    
        def to_wiki(*rules)
          # load html fragment
          doc = Nokogiri::HTML.fragment(@workingcopy) do |config|
            config.noblanks
          end
          
          # Remove all style content
          doc.xpath('.//style').each{ |n| n.remove }
          
          wiki_text = process_node(doc, false)
  
          remove_formats_from_whitespace(wiki_text).gsub(160.chr(Encoding::UTF_8),"&nbsp;")
        end
        
        private
        
        def process_node(node, process_text)
          node_html = ''
          if node.element?
            case node.node_name
            when 'p','div','h1','h2','h3','h4','h5','h6','h7','h8','h9','b','strong','i','em','u','strike','td','li'
              node_html.concat(process_content_node(node, true))
            when 'table','tr','ul','ol'
              node_html.concat(process_content_node(node, false))
            when 'br','hr'
              node_html.concat(process_simple_node(node))
            when 'img'
              node_html.concat(process_image_node(node))
            when 'a'
              node_html.concat(process_link_node(node))
            else
              node.children.each {|n| node_html.concat(process_node(n, process_text))}
            end
          elsif process_text and node.text?
            node_html.concat(process_text_node(node))
          else
            node.children.each {|n| node_html.concat(process_node(n, process_text))}
          end
          node_html
        end

        def process_content_node(node, process_text)
          simple_html_text = "<#{node.name}>"
          node.children.each {|n| simple_html_text.concat(process_node(n, true))}
          simple_html_text.concat("</#{node.name}>")
          simple_html_text
        end

        def process_simple_node(node) 
          "<#{node.name} />"
        end

        def process_image_node(node)
          image_html = "<img src=\"#{node[:src]}\" "
          image_html << "alt=\"#{node[:alt]}\" " if node[:alt]
          image_html << "title=\"#{node[:title]}\" " if node[:title]
          image_html << "/>"
          image_html
        end

        def process_link_node(node)
          simple_html_text = "<a href=\"#{node[:href]}\">"
          node.children.each {|n| simple_html_text.concat(process_node(n, true))}
          simple_html_text << "</a>"
          simple_html_text
        end

        def process_text_node(node)
          node.to_s.gsub(/[\r\n]/,' ').squeeze(" ")
        end
        
        def remove_formats_from_whitespace(html)
          loop do
            break if html.gsub!(/<\/([biu]|strike)>([\s\u00A0]*)<\1>/,'\2').nil?
          end
          html
        end
        
      end
    end
  end
end