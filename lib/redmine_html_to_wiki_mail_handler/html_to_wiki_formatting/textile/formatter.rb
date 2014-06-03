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
          
          wiki_text = process_node(doc, {:table? => false, :list_depth => 0, :pre? => false, :bold? => false, :italic? => false, :underline? => false, :strike? => false}, {})
  
          wiki_text
        end
        
        private
        
        # recurive html node processor
        # returns wiki text
        def process_node(node, state_info, options)
          node_text = ''
          if node.element?
            case node.node_name
            when 'p', 'div'
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              if state_info[:table?]
                node_text.concat("\n")
              else
                node_text.concat("\n\n")
              end
            when 'h1','h2','h3','h4','h5','h6','h7','h8','h9'
              #puts "tag: #{node.node_name}"
              node_text.concat(node.node_name + '. ')
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              node_text.concat("\n\n")
              #puts node_text
            when 'b', 'strong'
              state_info[:bold?] = true
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              state_info[:bold?] = false
              
              node_text.gsub!(/^(\s*)\*(\s*)\*$/,'\1\2')
            when 'i', 'em'
              state_info[:italic?] = true
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              state_info[:italic?] = false
            when 'u'
              state_info[:underline?] = true
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              state_info[:underline?] = false
            when 'strike'
              state_info[:strike?] = true
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              state_info[:strike?] = false
            when 'br'
              node_text.concat("\n")
            when 'hr'
              node_text.concat("---\n")
            when 'table'
              state_info[:table?] = true
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              state_info[:table?] = false
              node_text.concat("\n")
            when 'tr'
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              node_text.concat("|\n")
            when 'td'
              node_text.concat("|")
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
              node_text.gsub!(/(\n*)$/,'')
            else
              node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
            end
          elsif node.text?
            #puts "text"
            temp_text = node.to_s.gsub(/[\r\n]/,' ').squeeze(" ")
            
            prepend_space = !temp_text.lstrip!.nil?
            if prepend_space
              node_text.concat(' ')
            end
            prepend_nbsp = !node.to_s.gsub!(/^[\u00A0]/,'').nil?
            node_text.concat('+') if state_info[:underline?]
            node_text.concat('-') if state_info[:strike?]
            node_text.concat('*') if state_info[:bold?]
            node_text.concat('_') if state_info[:italic?]
            node_text.concat(node.to_s.gsub(/[\r\n]/,' ').lstrip)
            append_space = !node_text.rstrip!.nil?
            node_text.concat('_') if state_info[:italic?]
            node_text.concat('*') if state_info[:bold?]
            node_text.concat('-') if state_info[:strike?]
            node_text.concat('+') if state_info[:underline?]
            if append_space
              node_text.concat(' ')
            end
            node_text.gsub!(160.chr(Encoding::UTF_8),"&nbsp;")
            #puts node_text
          else
            node.children.each {|n| node_text.concat(process_node(n, state_info, options))}
          end
          node_text
        end
        
      end
    end
  end
end