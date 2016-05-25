class FileParser
  def self.parse(filename)
    res = []
    CSV.foreach(filename, col_sep: ';', encoding: 'UTF-8') do |row|
      eng = get_eng_words(row[0])
      rus = get_rus_words(row[1])
      if !rus.nil? && !eng.nil?
        res << [eng, rus]
      end
    end
    res
  end

  def self.get_rus_words(sentence)
    if sentence.nil?
      return nil
    end
    sentence.scan(/(^|\(| )([А-Яа-я]+([-'][А-Яа-я]+)*)(?=([\.\),:; ]|$))/).map { |m| m[1] }
  end

  def self.get_eng_words(sentence)
    if sentence.nil?
      return nil
    end
    sentence.scan(/(^|\(| )([A-Za-z]+([-'][A-Za-z]+)*'?)(?=([\.\),:; ]|$))/).map { |m| m[1] }
  end
end