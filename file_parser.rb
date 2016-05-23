class FileParser
  def self.parse(filename)
    res = []
    CSV.foreach(filename, col_sep: ';', encoding: 'UTF-8') do |row|
      res << [get_eng_words(row[0]), get_rus_words(row[1])]
    end
    res
  end

  def self.get_rus_words(sentence)
    sentence.scan(/(^|\(| )([А-Яа-я]+([-'][А-Яа-я]+)*)(?=([\.\),:; ]|$))/).map { |m| m[1] }
  end

  def self.get_eng_words(sentence)
    sentence.scan(/(^|\(| )([A-Za-z]+([-'][A-Za-z]+)*'?)(?=([\.\),:; ]|$))/).map { |m| m[1] }
  end
end