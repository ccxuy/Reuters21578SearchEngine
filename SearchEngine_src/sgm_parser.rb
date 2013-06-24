require 'rubygems'
require 'nokogiri'
require 'benchmark'

require_relative 'DBStorage'
require_relative 'word_proc'

class XMLParser
  def initialize (file_path)
    @doc_node = "REUTERS"
    @doc_id = "NEWID"
    @doc_attribute = ["DATE","TOPICS","PEOPLE","ORGS","EXCHANGES","COMPANIES","UNKNOWN"]
    @text_node = "TEXT"
    @text_attribute = ["TITLE","DATELINE"]
    @text_body = "BODY"

    @rec_word=[]
    @storage = DBStorage.new
    @tool_wordproc = WordsProcessor.new
    input = ''

    File.open(file_path,"r") do |file|
      while line  = file.gets
        input<<line
      end
    end

    @xml = Nokogiri::XML(input)
  rescue Errno::ENOENT
    puts 'WARNING: FILE NOT FOUND!!!'
  end

  def save_document
    #Benchmark.bmbm(10) do |timer|
    #timer.report{
    @conn = Mongo::Connection.new
    @db   = @conn['search-db']
    @coll = @db['words1']
    @rec_word.each do |rec|
      @coll.insert({'word_str'=>rec[0],'word_info'=>rec[1],'word_feq'=>rec[2]})
    end
    #}
    #end

  end

  def parse_document
    if(nil==@xml)
      puts "NO DOCUMENT READED"
      return
    end

    @document_id = 0
    @document_bson = {}

    @token_text = ''
    @token_feq = 0

    parse_doc_count = 0

    #Benchmark.bmbm(10) do |timer|

    #FIXME: change to Hpricot
    @xml.xpath("//"+@doc_node).each{  |d|
      #print "Parsing "+(parse_doc_count+=1).to_s
      if(doc_id = d.attributes[@doc_id] != nil)
        #TODO: save doc_id to data set    RESULT OK
        @document_id = d.attributes[@doc_id].text
        #puts '  doc_id = '+@document_id +'   '
        #parse attribute
        d.elements.each do |d_attr|
          @doc_attribute.each do |attr|
            #TODO: save text to data set  RESULT OK
            if(d_attr.name==attr)
              #puts d_attr.name + ' => ' + d_attr.text
            end
          end
        end


        #parse text
        d.xpath('./'+@text_node).each do |t|
          @text_attribute.each{|t_attr|
            #TODO: save text to data set
            t.xpath('./'+t_attr).each do |node|
              #puts node.name + ' => ' + node.text
            end
          }
          #TODO: parse each single word
          #timer.report{
          t.xpath('./'+@text_body).each do |body|
            word_pos=0
            body.text.scan(/\w+/) do |word|
              word_pos+=1
              #Check stop words
              if @tool_wordproc.is_stop_word(word)
                next
              end
              #Do lemmatization
              word = @tool_wordproc.do_lemmatization(word)

              doc_info = [] << [@document_id,word_pos]
              #Check duplicate words
              flag_dup = false
              @rec_word.each do |dat|
                if dat[0]==word
                  flag_dup =true
                  dat[1]<<doc_info
                  dat[2]+=1
                end
              end
              if flag_dup == false
                @rec_word<<[word,doc_info,1]
              end
            end
          end
          #}

          #timer.report{
          #datas.each do |dat|
          #  @storage.insertWord(dat[0],dat[1],dat[2])
          #end
          #}
        end
      else
        raise "DOCUMENT LACK OF ID"
      end
    }


    #end  #end of benchmark
  end
end
