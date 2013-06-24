require 'mongo'
class SearchController < ApplicationController
  def index
    @query = params[:qt]
    respond_to do |format|
      format.html { redirect_to @query, notice: 'Test was successfully created.' }
    end
  end
  def search
    @query = params[:query_term].nil? ? 1 : params[:query_term]
    p @query
  end
  def result
    #@lem = Lemmatizer.new

    conn = Mongo::Connection.new
    db   = conn['search-db']
    @coll_word= db['word']
    @coll_article= db['article']
    @query = params[:qt]

    @b_quote = false


    p '-----------------------------'
    puts 'QUERY:'+@query
    @result_set = []
    #If contains QUOTATION mark ""
    if (0<(res_word=@query.scan(/(?<=\").+(?=\")/)).count)
      query_words = res_word[0].scan(/\w+/)
      #query_words.each do |word|
      #  word=@lem.lemma(word)
      #end
      @b_quote = true
      puts 'USE QUOTE'
      @coll_word.find({'word_str'=>query_words[0]}).each {|rec|
        #USE RegExpress to search in raw text if match continuous, then add it
        word_info = rec['word_info']
        word_info.each do |w_i_key,article|
          puts article[0].to_i.inspect
          doc_id = article[0].to_i
          rec_article=@coll_article.find_one({'doc_id'=>doc_id})
          puts (rec_article).inspect
          if(nil!=rec_article)
            reg_exp =  Regexp.new(/(?<=[.?!]|^).+?#{res_word[0]}.+?[.!?]/,Regexp::IGNORECASE)
            summery = rec_article['doc_text'].gsub(/[^a-zA-z0-9,.!?]/,' ').scan(reg_exp).last
            @result_set << [doc_id,summery]
          else
            @result_set << [doc_id,"Article information retrieving ERROR."]
          end
        end
      }
      return
    else
      article_contain_term = Hash.new
      #TODO: Those not QUOTE, use Prod to calculate score.
      query_words =@query.scan(/\w+/)
      data_word = @coll_word.find({'word_str'=>query_words[0]})

      #Calculate value
      doc_n = @coll_article.count

      #TODO:ENSURE if query terms not in db, divide number =0?
      #TODO:tf to wt
      query_terms = Hash.new
      query_articles = Hash.new
      query_sort_articles = Hash.new
      #--Begin Calculate score
      query_words.each do |query_term|
        @coll_word.find({'word_str'=>query_term}).each {|rec|
          word_info = rec['word_info']
          word_info.each do |doc_id,pos|
            query_articles[doc_id]=@coll_article.find_one({'doc_id'=>doc_id})
          end
          query_terms[query_term]=rec
        }
      end
      query_articles.each do |q_a_key,query_doc|
        score = 0
        query_sqr_wt_sum = 0
        query_terms.each do |q_t_key,query_term|
          #puts query_term.inspect
          word_str = query_term['word_str']
          if(word_str==nil)
            query_doc['query_term']=Hash.new
            query_doc['query_term'][word_str]=Hash.new
            query_doc['query_term'][word_str]['word_str']=word_str
            query_doc['query_term'][word_str]['query_idf']=0
          else
            query_df = query_term['word_info'].count
            query_idf = Math.log10(doc_n/query_df)

            query_doc['query_term']=Hash.new
            query_doc['query_term'][word_str]=Hash.new
            query_doc['query_term'][word_str]['word_str']=word_str
            query_doc['query_term'][word_str]['query_idf']=query_idf

            query_sqr_wt_sum +=  query_idf * query_idf
          end
          summery = ""
          word_phase = word_str
          while(summery=="" && word_phase!="")
            reg_exp =  Regexp.new(/(?<=[.?!^]).+?#{word_phase}.+?[.!?]/,Regexp::IGNORECASE)
            summery = query_doc['doc_text'].gsub(/[^a-zA-z0-9,.!?]/,' ').scan(reg_exp).last
            word_phase = word_str[0..-2]
          end
          query_doc['summery'] = summery
          #puts "query_doc['summery'] =>>>"+query_doc['doc_text'].gsub(/[^a-zA-z0-9,.!?]/,' ').inspect
          #puts reg_exp.inspect
          #puts query_doc['summery'].inspect
        end
        query_terms.each do |q_t_key,query_term|
          word_str = query_term['word_str']
          wt = query_idf = query_doc['query_term'][word_str]['query_idf']
          query_doc['query_term'][word_str]['query_nlize']= query_nlize =  (wt/Math.sqrt(query_sqr_wt_sum))
          doc_nlize = query_doc['doc_term'][word_str]['nlize'].to_f
          if(doc_nlize==nil)
            doc_nlize=0
          end
          prod=query_nlize*doc_nlize
          score += prod
        end
        query_doc['score']=score
        query_sort_articles[score]=query_doc
        query_doc['query_term']=nil
      end
      #--End-- Calculate score
      max_a = query_sort_articles.count
      qs_articles = query_sort_articles.sort
      #puts query_sort_articles.inspect
      if(max_a<10)
        qs_articles[0..max_a].each do |q_sa_key,s_doc|
          @result_set << [s_doc['doc_id'],s_doc['summery']]
        end
      else
        qs_articles[max_a-10..max_a].each do |q_sa_key,s_doc|
          @result_set << [s_doc['doc_id'],s_doc['summery']]
        end
      end
      #
      puts "@result_set "+@result_set.count.to_s
      #@result_set << [doc_id,summery]
    end


    p '-----------------------------'
    @display = @res_word
  end
end
