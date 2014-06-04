require 'nokogiri'
require 'pp'

module RedmineHtmlToWikiMailHandler
  module HtmlToWikiFormatting
    module Textile
      class Formatter < String
  
        def initialize(html)
          super(html)
          @workingcopy = html
        end
        
        def logger
          Rails.logger
        end
    
        def to_wiki(*rules)
          # load html fragment
          doc = Nokogiri::HTML.fragment(@workingcopy) do |config|
            config.noblanks
          end
          
          # Remove all style content
          doc.xpath('.//style').each{ |n| n.remove }
          
          process_node(doc, {:table? => false, :list_depth => 0, :pre? => false, :bold => '', :italic => '', :underline => '', :strike => ''}, false).rstrip
        end
        
        private
        
        def process_paragraph_node(node, state_info)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, state_info, true))}
          node_text.gsub!(/([ ]|&nbsp;)+$/,'')
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
          
          node_text.gsub!(/^([\s\u00A0]*)\*([\s\u00A0]*)\*$/,'\1\2')
          node_text.squeeze!(" ")
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

        def process_text_node(node, state_info)
          node_text = ''
          node_words = node.to_s.gsub(/[\r\n]/,' ').squeeze(" ")
            
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
          
          font_modifiers = "#{state_info[:underline]}#{state_info[:strike]}#{state_info[:bold]}#{state_info[:italic]}"
          
          node_text << prepend_spaces << font_modifiers << node_words << font_modifiers.reverse << append_spaces
          
          node_text.gsub!(160.chr(Encoding::UTF_8),"&nbsp;")
          
          node_text
        end

        # recurive html node processor
        # returns wiki text
        def process_node(node, state_info, process_text)
          # todo: lists
          # todo: images
          # todo: entities (&nbsp;)
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