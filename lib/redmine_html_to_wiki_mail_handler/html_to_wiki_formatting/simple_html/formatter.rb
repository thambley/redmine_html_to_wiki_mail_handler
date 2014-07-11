require 'nokogiri'
require 'pp'

module RedmineHtmlToWikiMailHandler
  module HtmlToWikiFormatting
    module SimpleHtml
      class Formatter < String
  
        def initialize(html)
          super(html)
          @working_copy = html
        end
    
        def to_wiki(*rules)
          # load html fragment
          doc = Nokogiri::HTML.fragment(@working_copy) do |config|
            config.noblanks
          end
          
          # Remove all style content
          doc.xpath('.//style').each{ |n| n.remove }
          
          wiki_text = "<div>#{process_node(doc, false)}</div>"
  
          clean_up_nbsp_for_formatting(remove_extra_formatting(wiki_text)).gsub(160.chr(Encoding::UTF_8),"&nbsp;")
        end
        
        private
        
        STYLES_RE = /^(color|width|height|border|background|padding|margin|font|text|float)(-[a-z]+)*:\s*((\d+%?|\d+px|\d+(\.\d+)?em|#[0-9a-f]+|[a-z]+)\s*)+$/i
        
        def sanitize_styles(str)
          styles = str.split(";").map(&:strip)
          styles.reject! do |style|
            !style.match(STYLES_RE)
          end
          styles.join(";")
        end
        
        def filtered_style_attribute(node)
          style_string = ""
          node_style = node[:style]
          if node_style
            filtered_style = sanitize_styles(node_style)
            if filtered_style.length > 0
              style_string = "style=\"#{filtered_style}\""
            end 
          end
          style_string
        end
        
        def process_node(node, process_text)
          node_html = ''
          if node.element?
            case node.node_name
            when 'p','div','h1','h2','h3','h4','h5','h6','h7','h8','h9','b','strong','i','em','u','strike','td','li'
              node_html.concat(process_content_node(node, true))
            when 'span'
              node_html.concat(process_span_node(node))
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
        
        def process_span_node(node)
          # find style properties.  If no acceptable style properties are found, just output text
          # at this time, only color and background color are acceptable
          simple_html_text = "<span #{filtered_style_attribute(node)}>"
          
          if simple_html_text == "<span >"
            simple_html_text = ''
            node.children.each {|n| simple_html_text.concat(process_node(n, true))}            
          else
            node.children.each {|n| simple_html_text.concat(process_node(n, true))}
            simple_html_text.concat("</span>")
          end
          
          simple_html_text
        end

        def process_content_node(node, process_text)
          simple_html_text = "<#{node.name} #{filtered_style_attribute(node)}>"
          node.children.each {|n| simple_html_text.concat(process_node(n, process_text))}
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
        
        def remove_extra_formatting(html)
          loop do
            break if html.gsub!(/<\/([biu]|strike)>([\s\u00A0]*)<\1>/,'\2').nil?
          end
          html
        end
        
        def clean_up_nbsp_for_formatting(html)
          #try to get real spaces around formatting tags instead of non breaking spaces which cause issues with textile formatting
          html.gsub!(/<\/([biu]|strike)>([\u00A0]) /,'</\1> \2')
          html.gsub!(/ ([\u00A0])<([biu]|strike)>/,'\1 <\2>')
          html.gsub!(/<\/([biu]|strike)>[\u00A0] /,'</\1> ')
          html.gsub!(/>[\u00A0]</,'> <')
          html
        end
        
      end
    end
  end
end