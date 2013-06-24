require_relative 'xml_parser'

@CategeryList = ["all-orgs-strings.lc.txt"]
@sgmFileList = []
@TestFileList = ["all-orgs-strings.lc.txt"]
puts Dir.glob('*/').each { | file | file.downcase }
Dir.chdir("../reuters21578-xml")
Dir.glob('reut2-0[0-9][0-9].xml').each { | file | @sgmFileList<<file }
#Dir.glob('reut2-001.xml').each { | file | @sgmFileList<<file }
puts @sgmFileList.inspect


parser = XMLParser.new
file_count=0
#Benchmark.bmbm(10) do |timer|

  #timer.report{
@sgmFileList.each(){ |fname|
  puts 'Processing FILE: '+fname
  parser.load_new_file(fname)
  parser.parse_document
}
  #}
  puts "END OF GET WORDS"

  parser.calculate_tfidf
  #p 'END OF TFIDF'

  #timer.report{
    parser.save_document
  #}
  puts "END OF SAVE WORDS"
#end
#@storage.print()
#puts "END OF LOAD WORDS"