require 'stanford-core-nlp'
require "lemmatizer"
StanfordCoreNLP.log_file = 'log.txt'

class WordsProcessor
  def initialize()
    #STOP WORDS
    stopword_fpath='../stop_words.txt'
    @l_stopword = Hash.new
    File.open(stopword_fpath,"r") do |line|
      while word  = line.gets
        word.scan(/\w+/){|w|
          @l_stopword[w]=nil
        }
      end
    end
    #p @l_stopword.inspect
    puts '$WordsProcessor> Stop words load : '+@l_stopword.count.to_s
    #Load library. WARNING::dcoref DOES NOT WORK
    #pipeline =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    #LEMMATIZATION
    @lem = Lemmatizer.new
    #@pipeline =  StanfordCoreNLP.load(:tokenize,:ssplit,:pos,:lemma, :parse)
    #puts '$WordsProcessor> Lemmatization library loaded.'
  end

  def is_stop_word(word)
    if @l_stopword.include? word
      return true
    end
    return false
  end

  def do_lemmatization(word)
    @lem.lemma(word)
  end

  #def do_nlp(raw_text)
  #  tokens = []
  #  text = StanfordCoreNLP::Text.new(raw_text)
  #  @pipeline.annotate(text)
  #  text.get(:sentences).each do |sentence|
  #    sentence.get(:tokens).each do |token|
  #      # Lemma (base form of the token)
  #      tokens << token.get(:lemma).to_s
  #    end
  #  end
  #  tokens
  #end
end