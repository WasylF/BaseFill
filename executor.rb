require_relative 'file_parser'
require_relative 'match_words'
require 'csv'

#maximum number of trying matches 1 line
MAX_REPEAT_NUMBER = 3
SLEEP_SECONDS = 7

# matches 1 line from file
# returns success status.
def do_iteration(line_number)
  begin
    my_translation = MatchTranslation.new(@words[line_number][0], @words[line_number][1])
    matches = my_translation.process_sentences
    matches.each do |key, value|
      p_o_s = @abbreviations[my_translation.part_of_speech[value]] || 'Unk.'
      @result["#{key}\t#{value}\t#{p_o_s}"] ||= 0
      @result["#{key}\t#{value}\t#{p_o_s}"] += 1
      puts "#{key}\t#{value}\t#{p_o_s}"
    end
  rescue
    return false
  end

  return true
end

@words = FileParser.parse(ARGV[0])
# @words = FileParser.parse("input-UTF8.csv")

@abbreviations= {'сущ.' => 'С', 'прил.' => 'П', 'числ.' => 'Ч', 'мест.' => 'М', 'гл.' => 'Г', 'нареч.' => 'Н',
                 'предл.' => 'ПРЕДЛ', 'союз' => 'СОЮЗ'}

@result = {}

start = ARGV[2].to_i
len = ARGV[3].to_i
#start = 0
#len = 7

len.times do |i|
  break if i + start >= @words.size
  repeat_number = 0

  while repeat_number < MAX_REPEAT_NUMBER do
    if do_iteration(i + start)
      puts "Iteration #{i} done"
      puts "\n"
      repeat_number = MAX_REPEAT_NUMBER
    else
      repeat_number += 1
      sleep(SLEEP_SECONDS)
      puts "Some errors occurred! \n #{$!}"
    end
  end
end


@result.each { |key, value| puts "#{key}\t#{value}" }

File.open(ARGV[1], 'w') do |file|
#File.open('test_output.txt', 'w') do |file|
  @result.each { |key, value| file.puts "#{key}\t#{value}" }
end
