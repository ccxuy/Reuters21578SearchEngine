require 'rubygems'
require 'nokogiri'
require 'benchmark'
#include Math

require_relative 'DBStorage'
require_relative 'word_proc'

class XMLParser
  def initialize ()
    @doc_node = "REUTERS"
    @doc_id = "NEWID"
    @doc_attribute = ["DATE","TOPICS","PEOPLE","ORGS","EXCHANGES","COMPANIES","UNKNOWN"]
    @text_node = "TEXT"
    @text_attribute = ["TITLE","DATELINE"]
    @text_body = "BODY"

    @rec_word=Hash.new
    @rec_article=Hash.new
    @log_err = []
    @storage = DBStorage.new
    @tool_wordproc = WordsProcessor.new

    @b_tfidf = false
  end

  def load_new_file(file_path)
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
      conn = Mongo::Connection.new
      db   = conn['search-db']
      coll_word= db['word']
      coll_article= db['article']
      puts '@rec_word count:' + @rec_word.count.to_s
      @rec_word.each do |rec|
        #p rec[1]#['word_info']
        coll_word.insert({'word_str'=>rec[1]['word_str'],
                          'word_info'=>rec[1]['word_info'],
                          'word_feq'=>rec[1]['word_feq']})
      end
      coll_word.create_index 'word_str'
      if(false==@b_tfidf)
        @rec_article.each do |rec|
          #p rec[1]
          coll_article.insert({'doc_id'=>rec[1]['doc_id'],
                               'doc_title'=>rec[1]['doc_title'],
                               'doc_dateline'=>rec[1]['doc_dateline'],
                               'doc_attribute'=>rec[1]['doc_attribute'],
                               'doc_text'=>rec[1]['doc_text']})
        end
      else
        @rec_article.each do |rec|
          #p rec[1]
          coll_article.insert({'doc_id'=>rec[1]['doc_id'],
                               'doc_title'=>rec[1]['doc_title'],
                               'doc_dateline'=>rec[1]['doc_dateline'],
                               'doc_attribute'=>rec[1]['doc_attribute'],
                               'doc_text'=>rec[1]['doc_text'],
                               'doc_term'=>rec[1]['doc_term']})
        end
      end
      coll_article.create_index 'id'
    #}
    #end

  end

  def calculate_tfidf
    doc_n = @rec_article.count

    @rec_article.each do |rec_id,rec_val|
      puts "calculate_tfidf > "+(rec_id).to_s
      idf = nil
      tf_wt = nil
      sum_sqt_wt = 0
      rec_val['doc_term'].each do |term_str,term_feq|
        df = @rec_word[term_str]['word_info'].count
        tf = @rec_word[term_str]['word_feq']
        #idf = Math.log10(doc_n/df)
        tf_wt = tf>0 ? 1+Math.log10(tf) : 0
        wt = tf_wt  #wt = tf_wt*idf
        #puts 'term_str='+term_str+' doc_n= '+doc_n.to_s+' df= '+df.to_s
        #puts 'wt= '+wt.to_s#+' tf_wt= '+tf_wt.to_s+' idf= '+idf.to_s
        #puts @rec_article[rec_id]['doc_term'][term_str]
        @rec_article[rec_id]['doc_term'][term_str]['wt']=wt
        sum_sqt_wt += wt*wt
      end

      rec_val['doc_term'].each do |term_str,term_feq|
        wt = @rec_article[rec_id]['doc_term'][term_str]['wt']
        @rec_article[rec_id]['doc_term'][term_str]['nlize'] = (wt/Math.sqrt(sum_sqt_wt)).to_s
        #p Math.sqrt(sum_sqt_wt)==0
        #p @rec_article[rec_id]['doc_term'][term_str]
      end

      @b_tfidf=true
    end
    #@rec_word.each do |rec|
    #  df = rec[1]['word_info'].count
    #  idf = Math.log10(doc_n/df)   #.to_f?
    #  rec[]
    #  tf =
    #  tf_wt = 1+Math.log10(tf)
    #  coll_word.insert({'word_str'=>rec[1]['word_str'],'word_info'=>rec[1]['word_info'].to_a,'word_feq'=>rec[1]['word_feq']})
    #  rec[1]['word_info'].each do |doc_info|
    #    doc_info[1].count
    #  end
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

    @xml.xpath("//"+@doc_node).each{  |d|
      #puts "Parsing "+(@document_id).to_s
      if(d.attributes[@doc_id] == nil)
        raise "DOCUMENT LACK OF ID"
      end
      @document_id = d.attributes[@doc_id].text  #save doc_id to data set
      #@rec_article[@document_id]=[@document_id,nil,nil,[],{}]
      @rec_article[@document_id]=Hash.new
      @rec_article[@document_id]['doc_term']=Hash.new
      @rec_article[@document_id]['doc_id']=@document_id
      #p @rec_article[@document_id].inspect
      d.elements.each do |d_attr|      #for each attribute in <REUTERS>
        if(@doc_attribute.include? d_attr.name) #for each attribute of document <DATE>...
          #@rec_article[@document_id][3]<<[d_attr.name,d_attr.text]
          if(nil==@rec_article[@document_id]['doc_attribute'])
            @rec_article[@document_id]['doc_attribute']=[[d_attr.name,d_attr.text]]
          else
            @rec_article[@document_id]['doc_attribute']<<[d_attr.name,d_attr.text]
          end
          #p @rec_article[@document_id].inspect
        end
        if(@text_node.include? d_attr.name)
          d_attr.elements.each do |t_attr|
            if(t_attr.name.eql?@text_attribute[0]) #for  <TITLE>
              @rec_article[@document_id]['doc_title']=t_attr.text
            elsif(t_attr.name.eql?@text_attribute[1]) #for  <DATELINE>
              @rec_article[@document_id]['doc_dateline']=t_attr.text                                       #puts  t_attr.text
            end
            #p @rec_article[@document_id].inspect
            if(@text_body.include? t_attr.name) #for <BODY> attribute in <TEXT>
              word_pos=0
              #begin
              if(nil==t_attr.text)
                 puts "WARNING!! > "+(@document_id).to_s+" text body reading failure detected!!"
              end
              @rec_article[@document_id]['doc_text']=t_attr.text
              t_attr.text.scan(/\w+/) do |word|
                word_pos+=1
                #Skip stop words
                if @tool_wordproc.is_stop_word(word.downcase)
                  next
                end
                #Do lemmatization
                word = @tool_wordproc.do_lemmatization(word)

                #Check duplicate words
                if(@rec_word.include?word)
                  keyword_info = @rec_word[word]
                  if(nil==keyword_info['word_info'][@document_id])
                    keyword_info['word_info'][@document_id]=[@document_id,[word_pos]]
                  else
                    keyword_info['word_info'][@document_id][1]<<word_pos
                  end
                  keyword_info['word_feq'] += 1
                else
                  token_info = Hash.new
                  doc_info = Hash.new
                  doc_info[@document_id] = [@document_id,[word_pos]]
                  token_info['word_str'] = word
                  token_info['word_info'] = doc_info
                  token_info['word_feq'] = 1
                  @rec_word[word] = token_info
                end
                if(@rec_article[@document_id]['doc_term'].include?word)
                  @rec_article[@document_id]['doc_term'][word]['term_feq'] +=1
                else
                  @rec_article[@document_id]['doc_term'][word] ={'term_feq'=>1}
                end
              end
              #rescue ArgumentError
              #  puts "INVALID CHARACTERS IN DOCUMENT OF ID"+@document_id.to_s
              #  @err_log<<["INVALID CHARACTERS",@document_id.to_s]
              #end
            end
          end

        end
      end
      #parse_doc_count+=1
      #if(parse_doc_count>10)
      #  break
      #end
    }


    #end  #end of benchmark
  end
end
