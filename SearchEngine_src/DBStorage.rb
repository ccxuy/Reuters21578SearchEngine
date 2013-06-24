require 'mongo'
class DBStorage
  def initialize
    #make a connection
    @conn = Mongo::Connection.new
    @db   = @conn['search-db']
    @coll = @db['words']
  end

  def insertWord(word_str,doc_info, word_pos)
    word_feq=1
    if 0== (old_col=get_word_feq(word_str)).count
      #puts "doc_id" + doc_id
      @coll.insert({'word_str'=>word_str,'doc_info'=>doc_info,'word_feq'=>word_feq})
    else
      old_col.each do |old_data|
        word_feq = old_data['word_feq'].to_i+1
        new_doc_info = old_data['doc_info']<<doc_info
        @coll.update({'word_str'=>word_str},{ '$set'=>{'doc_info'=>new_doc_info,'word_feq'=>word_feq} })
        #puts 'DUPLICATE DETECTED!! '+ word_feq.to_s
        break
      end
    end
    @coll.create_index 'word_str'
  end

  def get_word_feq(word_str)
    @coll.find('word_str'=>word_str)
  end

  def clean
    @coll.remove
  end

  def print
    #Print all
    @coll.find.each { |doc| puts doc.inspect }
  end
end
#DBStorage.new().print()