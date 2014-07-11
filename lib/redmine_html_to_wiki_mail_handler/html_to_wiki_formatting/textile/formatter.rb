require 'nokogiri'
require 'pp'

module RedmineHtmlToWikiMailHandler
  module HtmlToWikiFormatting
    module Textile
      class Formatter < String
      
        ENTITIES = [["&#169;","(C)"],
                    ["&#174;","(R)"],
                    ["&#215;", " x "],
                    ["&#8211;","-"],
                    ["&#8212;", "--"],
                    ["&#8213;", "--"],
                    ["&#8217;", "'"],
                    ["&#8220;", '"'], 
                    ["&#8221;", '"'],
                    ["&#8230;", "..."],
                    ["&#8482;","(TM)"]]
        
        CHARACTERS = [[169.chr(Encoding::UTF_8),  "(C)"],
                      [174.chr(Encoding::UTF_8),  "(R)"],
                      [215.chr(Encoding::UTF_8),  " x "],
                      [8211.chr(Encoding::UTF_8), "-"],
                      [8212.chr(Encoding::UTF_8), "--"],
                      [8213.chr(Encoding::UTF_8), "--"],
                      [8217.chr(Encoding::UTF_8), "'"],
                      [8220.chr(Encoding::UTF_8), '"'], 
                      [8221.chr(Encoding::UTF_8), '"'],
                      [8230.chr(Encoding::UTF_8), "..."],
                      [8482.chr(Encoding::UTF_8), "(TM)"]]
                      
        SPECIAL_CHARACTERS = [["*","&#42;"],
                              ["+","&#43;"],
                              ["-","&#45;"],
                              ["_","&#95;"],
                              ["%","&#37;"],
                              ["!","&#33;"],
                              ["|","&#124;"]]
  
        def initialize(html)
          super(html)
          @working_copy = html
          @in_table = false
          @list_depth = 0
          @list_character = ''
          #@in_pre = false
          @allow_style = true
        end
    
        def to_wiki(*rules)
          html = RedmineHtmlToWikiMailHandler::HtmlToWikiFormatting.formatter_for(:simple_html).new(@working_copy).to_wiki
          
          # load html fragment
          doc = Nokogiri::HTML.fragment(html) do |config|
            config.noblanks
          end
          
          # Remove all style content
          doc.xpath('.//style').each{ |n| n.remove }
          
          wiki_text = process_node(doc, false).rstrip
  
          wiki_text.gsub!(160.chr(Encoding::UTF_8),"&nbsp;")
          
          wiki_text.gsub!(/([*-+%_])\1/,'\1<notextile></notextile>\1')
          wiki_text.gsub!(/ &nbsp;([*-+%_])/,'&nbsp; \1')
          
          #return 
          wiki_text.lines.map{|line| update_line(line)}.join
        end
        
        private
        
        # perform per line replacement
        def update_line(line_text)
          updated_line_text = line_text
          # replace outlook list format with textile list format:
          updated_line_text.gsub!(/^[\u00b7]&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; /,"* ") # middot - middle dot
          updated_line_text.gsub!(/^[\u2022]&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; /,"* ") # bull   - bullet
          updated_line_text.gsub!(/^o&nbsp;&nbsp; /,"** ") # second level bullet
          updated_line_text.gsub!(/^[\u00A7]&nbsp; /,"*** ") # 3rd level bullet (section entity)
          
          updated_line_text.gsub!(/^[0-9]+\.&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; /, "# ")
          
          updated_line_text
        end
        
        def apply_formatting(text, format, style)
          formatted_text = ''
          
          if @allow_style && style && style.length > 0
            text_style = "{#{style}}"
          else
            text_style = ''
          end
          
          text.each_line do |line|
            prepend_spaces, node_words, append_spaces = extract_node_words( text )
            if node_words.length > 0
              if text_style.length > 0 && node_words =~ /^[!*%_+-]/
                formatted_text << prepend_spaces << format << text_style << '<notextile></notextile>' << node_words << format << append_spaces
              else
                formatted_text << prepend_spaces << format << text_style << node_words << format << append_spaces
              end
            else
              formatted_text << prepend_spaces
            end
          end
          formatted_text
        end
        
        def process_paragraph_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, true))}
          node_text.gsub!(/[ \u00A0]+$/,'')
          node_text.gsub!(/^[ ]+/,'')
          node_text.concat("\n")
          node_text.gsub!(/[\n]+$/,"\n")
          node_text
        end
        
        def process_span_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, true))}
          if @allow_style
            apply_formatting(node_text, '%', node[:style])
          else
            node_text
          end
        end

        def process_header_node(node)
          node_text = ''
          node_text.concat("#{node.node_name}. ")
          node.children.each {|n| node_text.concat(process_node(n, true))}
          node_text.concat("\n\n")
          node_text
        end

        def process_bold_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, true))}
          apply_formatting(node_text, '*', node[:style])
        end

        def process_italic_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, true))}
          apply_formatting(node_text, '_', node[:style])
        end

        def process_underline_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, true))}
          apply_formatting(node_text, '+', node[:style])
        end

        def process_strike_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, true))}
          apply_formatting(node_text, '-', node[:style])
        end

        def process_table_node(node)
          node_text = ''
          was_in_table = @in_table
          @in_table = true
          node.children.each {|n| node_text.concat(process_node(n, false))}
          @in_table = was_in_table
          node_text.concat("\n")
          node_text
        end

        def process_table_row_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, false))}
          node_text.concat("|\n")
          node_text
        end

        def process_table_data_node(node)
          node_text = ''
          node_text.concat("|")
          node.children.each {|n| node_text.concat(process_node(n, true))}
          node_text.gsub!(/[\s]+$/,'')
          node_text
        end

        def process_line_break_node(node)
          node_text = ''
          node_text.concat("\n")
          node_text
        end

        def process_hrule_node(node)
          node_text = ''
          node_text.concat("\n---\n\n")
          node_text
        end

        def image_filename(node)
          image_src = node[:src]
          image_src.gsub!(/cid:([^@]+)@.+/,'\1')
          image_src
        end

        def image_alt(node)
          alt_text = node[:alt] || node[:title] || ''
          if alt_text = node[:src]
            alt_text = ''
          end
          alt_text.gsub!(/^(Description: )*/,"")
          if alt_text.length > 0
            alt_text = "(#{alt_text})"
          end
          alt_text
        end

        def process_image_node(node)
          "!#{image_filename(node)}#{image_alt(node)}!"
        end

        def process_link_node(node)
          link_text = ''
          
          was_allow_style = @allow_style
          @allow_style = false
          node.children.each {|n| link_text.concat(process_node(n, true))}
          
          if m = /^(?<prepend_spaces>[\s\u00A0]*)(?<image_text>[\!][^\!]+[\!])(?<append_spaces>[\s\u00A0]*)$/.match(link_text)
            link_text = "#{m[:prepend_spaces]}#{m[:image_text]}:#{node[:href]}#{m[:append_spaces]}"
          else
            test_link_text = link_text.strip
            while test_link_text.sub!(/^([\*\-\_\+])(.+)\1$/, '\2')
            end
            
            if node[:href] != test_link_text and node[:href] != "mailto:#{test_link_text}" # mailto links are automatically created.
              if node[:href] != "http://#{test_link_text}" and node[:href] != "http://#{test_link_text}/"
                link_text = "\"#{link_text}\":#{node[:href]}"
              end
            end
          end
          
          @allow_style = was_allow_style
          
          link_text
        end

        def process_list_node(node, list_character)
          node_text = ''
          
          previous_list_character = @list_character
          @list_character = list_character
          @list_depth += 1
          
          node.children.each {|n| node_text.concat(process_node(n, true))}
          
          @list_depth -= 1
          @list_character = previous_list_character
          
          node_text.concat("\n")
          node_text
        end

        def process_list_item_node(node)
          node_text = ''
          node.children.each {|n| node_text.concat(process_node(n, true))}
         
          if !/^[\n]*([\#\*])\1* /.match(node_text)
            node_text = "#{@list_depth.times.collect {@list_character}.join('')} #{node_text}\n"
          end
          
          node_text
        end

        def replace_entities(node_text)
          ENTITIES.each do |htmlentity, textileentity|
            node_text.gsub!(htmlentity, textileentity)
          end
          node_text
        end
        
        def replace_characters(node_text)
          CHARACTERS.each do |character, textileentity|
            node_text.gsub!(character, textileentity)
          end
          node_text
        end
        
        def replace_special_characters(node_text)
          SPECIAL_CHARACTERS.each do |character, textileentity|
            node_text.gsub!(character, textileentity)
          end
          node_text
        end
        
        def clean_up_node_words(node_text)
          replace_special_characters(replace_characters(replace_entities(node_text)))
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

        def process_text_node(node)
          clean_up_node_words(node.to_s.gsub(/[\r\n]/,' ').squeeze(" "))
        end

        # recurive html node processor
        # returns wiki text
        def process_node(node, process_text)
          node_text = ''
          if node.element?
            case node.node_name
            when 'p', 'div'
              node_text.concat(process_paragraph_node(node))
            when 'span'
              node_text.concat(process_span_node(node))
            when 'h1','h2','h3','h4','h5','h6','h7','h8','h9'
              node_text.concat(process_header_node(node))
            when 'b', 'strong'
              node_text.concat(process_bold_node(node))
            when 'i', 'em'
              node_text.concat(process_italic_node(node))
            when 'u'
              node_text.concat(process_underline_node(node))
            when 'strike'
              node_text.concat(process_strike_node(node))
            when 'br'
              node_text.concat(process_line_break_node(node))
            when 'hr'
              node_text.concat(process_hrule_node(node))
            when 'table'
              node_text.concat(process_table_node(node))
            when 'tr'
              node_text.concat(process_table_row_node(node))
            when 'td'
              node_text.concat(process_table_data_node(node))
            when 'ul'
              node_text.concat(process_list_node(node, '*'))
            when 'ol'
              node_text.concat(process_list_node(node, '#'))
            when 'li'
              node_text.concat(process_list_item_node(node))
            when 'img'
              node_text.concat(process_image_node(node))
            when 'a'
              node_text.concat(process_link_node(node))
            else
              node.children.each {|n| node_text.concat(process_node(n, process_text))}
            end
          elsif process_text and node.text?
            node_text.concat(process_text_node(node))
          else
            node.children.each {|n| node_text.concat(process_node(n, process_text))}
          end
          node_text
        end
        
      end
    end
  end
end