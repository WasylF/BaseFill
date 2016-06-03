require_relative 'file_parser'
require_relative 'match_words'
require 'csv'

@words = FileParser.parse(ARGV[0])
# @words = FileParser.parse("input-UTF8.csv")

abbreviations= {'сущ.' => 'С', 'прил.' => 'П', 'числ.' => 'Ч', 'мест.' => 'М', 'гл.' => 'Г', 'нареч.' => 'Н',
                'предл.' => 'ПРЕДЛ', 'союз' => 'СОЮЗ'}

@result = {}

start = ARGV[2].to_i
len = ARGV[3].to_i
#start = 0
#len = 7

len.times do |i|
  break if i + start >= @words.size

  my_translation = MatchTranslation.new(@words[i + start][0], @words[i + start][1])
  matches = my_translation.process_sentences
  matches.each do |key, value|
    p_o_s = abbreviations[my_translation.part_of_speech[value]] || 'Unk.'
    @result["#{key}\t#{value}\t#{p_o_s}"] ||= 0
    @result["#{key}\t#{value}\t#{p_o_s}"] += 1
    puts "#{key}\t#{value}\t#{p_o_s}"
  end
  puts "Iteration #{i} done"
  puts "\n"
end


@result.each {|key, value| puts "#{key}\t#{value}" }

File.open(ARGV[1], 'w') do |file|
#File.open('test_output.txt', 'w') do |file|
  @result.each {|key, value| file.puts "#{key}\t#{value}" }
end
