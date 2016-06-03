require 'set'

class FileParser
  def self.parse(filename)
    res = []
    total_rus = 0
    total_eng = 0
    all_rus = Set.new
    all_eng = Set.new

    line_number = 0

    CSV.foreach(filename, col_sep: ';', encoding: 'UTF-8') do |row|
      line_number += 1
      if !row[0].nil? && !row[1].nil?
        eng = get_eng_words(row[0].force_encoding(Encoding::UTF_8))
        rus = get_rus_words(row[1].force_encoding(Encoding::UTF_8))
        if !rus.nil? && !eng.nil?
          if rus.any? && eng.any?
            all_rus.merge(rus)
            all_eng.merge(eng)
            total_eng += eng.size
            total_rus += rus.size

            res << [eng, rus]
          end
        end
      end

      puts "#{line_number} lines parsed" if line_number % 10000 == 0

    end

    print_statistics(line_number, total_rus, total_eng, all_rus.length, all_eng.length)

    res
  end

  def self.print_statistics(line_number, total_rus, total_eng, unique_rus, unique_eng)
    puts "\n"
    puts '############################'
    puts '############################'
    puts '############################'
    puts "\n"
    puts 'file_parser statistic:'
    puts "#{line_number} lines parsed"
    puts "extract rus: #{total_rus}    extract eng #{total_eng}"
    puts "unique rus: #{unique_rus}   unique eng: #{unique_eng}"
    puts "\n"
    puts '############################'
    puts '############################'
    puts '############################'
    puts "\n"
  end


  def self.get_rus_words(sentence)
    if sentence.nil?
      return nil
    end
    sentence.scan(/(^|\(|\)| |\t|\.|,|;|:|<|>|\#|\$|\*|\[|\]|\%|\@|\!|\?|\+)([А-Яа-я]+([-][А-Яа-я]+)*)(?=(\(|\)| |\t|\.|,|;|:|<|>|\#|\$|\*|\[|\]|\%|\@|\!|\?|\+|$))/).map { |m| m[1] }
  end


  def self.get_eng_words(sentence)
    if sentence.nil?
      return nil
    end
    sentence.scan(/(^|\(|\)| |\t|\.|,|;|:|<|>|\#|\$|\*|\[|\]|\%|\@|\!|\?|\+)([A-Za-z]+([-'][A-Za-z]+)*)(?=(\(|\)| |\t|\.|,|;|:|<|>|\#|\$|\*|\[|\]|\%|\@|\!|\?|\+|$))/).map { |m| m[1] }
  end
end