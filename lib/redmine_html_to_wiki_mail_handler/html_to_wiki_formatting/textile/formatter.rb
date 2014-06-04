require 'nokogiri'
require 'pp'

module RedmineHtmlToWikiMailHandler
  module HtmlToWikiFormatting
    module Textile
      class Formatter < String
      
        ENTITIES = [
          ["&#8220;", '"'], ["&#8221;", '"'], ["&#8212;", "--"], ["&#8212;", "--"],
          ["&#8211;","-"], ["&#8230;", "..."], ["&#215;", " x "], ["&#8482;","(TM)"],
          ["&#174;","(R)"], ["&#169;","(C)"], ["&#8217;", "'"]
        ]
  
        def initialize(html)
          super(html)
          @workingcopy = html
        end
        
        def logger
          Rails.logger
        end
    
        def to_wiki(*rules)
          html = replace_entities(@workingcopy)
          
          # load html fragment
          doc = Nokogiri::HTML.fragment(html) do |config|
            config.noblanks
          end
          
          # Remove all style content
          doc.xpath('.//style').each{ |n| n.remove }
          
          wiki_text = process_node(doc, {:table? => false, :list_depth => 0, :pre? => false, :bold => '', :italic => '', :underline => '', :strike => ''}, false).rstrip
  
          remove_formats_from_whitespace(wiki_text).gsub(160.chr(Encoding::UTF_8),"&nbsp;")
        end
        
        private
        
        def process_paragraph_node(node, state_info)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          node_text.gsub!(/[ \u00A0]+$/,'')
          node_text.gsub!(/^[ ]+/,'')
          node_text.concat("\n")
          node_text.gsub!(/[\n]+$/,"\n")
          node_text
        end

        def process_header_node(node, state_info)
          node_text = ''
          node_text.concat("#{node.node_name}. ")
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          node_text.concat("\n\n")
          node_text
        end

        def process_bold_node(node, state_info)
          node_text = ''
          state_info[:bold] = '*'
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          state_info[:bold] = ''
          
          node_text
        end

        def process_italic_node(node, state_info)
          node_text = ''
          state_info[:italic] = '_'
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          state_info[:italic] = ''
          node_text
        end

        def process_underline_node(node, state_info)
          node_text = ''
          state_info[:underline] = '+'
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          state_info[:underline] = ''
          node_text
        end

        def process_strike_node(node, state_info)
          node_text = ''
          state_info[:strike] = '-'
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          state_info[:strike] = ''
          node_text
        end

        def process_table_node(node, state_info)
          node_text = ''
          state_info[:table?] = true
          node.children.each {|n| node_text.concat(process_node(n, state_info, false))}
          state_info[:table?] = false
          node_text.concat("\n")
          node_text
        end

        def process_table_row_node(node, state_info)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, state_info, false))}
          node_text.concat("|\n")
          node_text
        end

        def process_table_data_node(node, state_info)
          node_text = ''
          node_text.concat("|")
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          node_text.gsub!(/[\s]+$/,'')
          node_text
        end

        def process_line_break_node(node, state_info)
          node_text = ''
          node_text.concat("\n")
          node_text
        end

        def process_hrule_node(node, state_info)
          node_text = ''
          node_text.concat("---\n")
          node_text
        end
        
        def replace_entities(html)
          ENTITIES.each do |htmlentity, textileentity|
            html.gsub!(htmlentity, textileentity)
          end
          html
        end

        # remove formatting around whitespace
        def remove_formats_from_whitespace(formatted_text)
          bullet_pattern = /^(?<bullets>[\*]+ )(?<line_text>.*)/
          formatted_whitespace_pattern = /([\+]?)([\-]?)([\*]?)([\_]?)([ \u00A0]+)\4\3\2\1/
          
          reformatted_text = ''

          formatted_text.each_line do |formatted_line|
            bullet_matches = bullet_pattern.match(formatted_line)
            if bullet_matches.nil?
              bullet_text = ''
            else
              bullet_text = bullet_matches[:bullets]
              formatted_line = bullet_matches[:line_text]
            end
            
            reformatted_text << bullet_text << formatted_line.gsub(formatted_whitespace_pattern, '\5')
          end
          
          reformatted_text
        end

        def font_modifiers(state_info)
          "#{state_info[:underline]}#{state_info[:strike]}#{state_info[:bold]}#{state_info[:italic]}"
        end

        def extract_node_words(node_words)
          space_matches = /^(?<spaces>[\s\u00A0]+)/.match(node_words)
          
          if space_matches.nil?
            prepend_spaces = ''
          else
            prepend_spaces = space_matches[:spaces]
            node_words.gsub!(/^[\s\u00A0]+/,'')
          end
          
          space_matches = /(?<spaces>[\s\u00A0]+)$/.match(node_words)
          
          if space_matches.nil?
            append_spaces = ''
          else
            append_spaces = space_matches[:spaces]
            node_words.gsub!(/[\s\u00A0]+$/,'')
          end
          
          [prepend_spaces, node_words, append_spaces]
        end

        def process_text_node(node, state_info)
          node_text = ''
            
          prepend_spaces, node_words, append_spaces = extract_node_words( node.to_s.gsub(/[\r\n]/,' ').squeeze(" ") )
          
          start_font_modifier = font_modifiers(state_info)
          
          node_text << prepend_spaces << start_font_modifier << node_words << start_font_modifier.reverse << append_spaces
          
          node_text
        end

        # recurive html node processor
        # returns wiki text
        def process_node(node, state_info, process_text)
          # todo: lists
          # todo: images
          # todo: links
          node_text = ''
          if node.element?
            case node.node_name
            when 'p', 'div'
              node_text.concat(process_paragraph_node(node, state_info))
            when 'h1','h2','h3','h4','h5','h6','h7','h8','h9'
              node_text.concat(process_header_node(node, state_info))
            when 'b', 'strong'
              node_text.concat(process_bold_node(node, state_info))
            when 'i', 'em'
              node_text.concat(process_italic_node(node, state_info))
            when 'u'
              node_text.concat(process_underline_node(node, state_info))
            when 'strike'
              node_text.concat(process_strike_node(node, state_info))
            when 'br'
              node_text.concat(process_line_break_node(node, state_info))
            when 'hr'
              node_text.concat(process_hrule_node(node, state_info))
            when 'table'
              node_text.concat(process_table_node(node, state_info))
            when 'tr'
              node_text.concat(process_table_row_node(node, state_info))
            when 'td'
              node_text.concat(process_table_data_node(node, state_info))
            else
              node.children.each {|n| node_text.concat(process_node(n, state_info, process_text))}
            end
          elsif process_text and node.text?
            node_text.concat(process_text_node(node, state_info))
          else
            node.children.each {|n| node_text.concat(process_node(n, state_info, process_text))}
          end
          node_text
        end
        
      end
    end
  end
end