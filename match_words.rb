#coding utf-8
require 'unicode'

class String
  def last(n)
    self[(self.length - n)..-1]
  end

  def downcase
    Unicode::downcase(self)
  end

  def downcase!
    self.replace downcase
  end

  def upcase
    Unicode::upcase(self)
  end

  def upcase!
    self.replace upcase
  end

  def capitalize
    Unicode::capitalize(self)
  end

  def capitalize!
    self.replace capitalize
  end
end

class MatchTranslation
  def initialize(eng_sentence, rus_sentence)
    eng_sentence.downcase!
    rus_sentence.downcase!

    @eng_sentence = eng_sentence.split(' ')
    @rus_sentence = rus_sentence.split(' ')

    # TODO: add words
    @useless_eng_words= %w(a the an on in by)
    @useless_rus_words= %w(а б бы в во на)

    @rus_endings = %w(am ax cm ex а ам ами ас ая е ев ей ем еми емя ею её и ие ий им ими ит ите их ишь ию ия иям иями иях м ми мя о ов ого ое ой ом ому ою оё у ум умя ут ух ую ют шь ю я ям ями ях ёй ёт ёте ёх ёшь)

    delete_useless!
    @rus_sentence = delete_endings(@rus_sentence)
  end


  def delete_useless!
    new_eng_sentence = @eng_sentence - @useless_eng_words
    new_rus_sentence = @rus_sentence - @useless_rus_words

    puts "Useless English words: #{(@eng_sentence - new_eng_sentence).join(', ')}"
    puts "Useless Russian words: #{(@rus_sentence - new_rus_sentence).join(', ')}"

    @end_sentence = new_eng_sentence
    @rus_sentence = new_rus_sentence
  end


  def delete_endings(words)
    without_endings = []
    words.each do |word|
      word_size = word.size
      if word_size <= 3
        puts "word: #{word}, size: #{word_size}"
        without_endings << word
      else
        flag = false
        3.downto(1).each { |i|
          ending = word.last(i)
          if @rus_endings.include?(ending)
            puts "word: #{word}, ending: #{ending}"
            without_endings << word[0, word_size - i]
            flag = true
            break
          end
        }
        unless flag
          puts "Ending not found for word: #{word}"
          without_endings << word
        end
      end
    end

    puts "Added words without endings: #{without_endings.join(', ')}"
    without_endings
  end


  def levenshtein_distance(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m + 1) { Array.new(n + 1) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i - 1] == t[j - 1] # adjust index into string
                    d[i - 1][j -1] # no operation required
                  else
                    [d[i - 1][j]+1, # deletion
                     d[i][j - 1]+1, # insertion
                     d[i - 1][j - 1]+1, # substitution
                    ].min
                  end
      end
    end

    d[m][n]
  end


  def calc_probability(actual_word, translation_word)
    d = levenshtein_distance(actual_word, translation_word)

    #puts "distance: #{d}"
    #puts "length: #{actual_word.size}"
    #puts "p: #{d * 1.0 / actual_word.size}"

    p = d == 0 ? 1.0 : 1.0 - d * 1.0 / actual_word.size
    p < 0 ? 0.0 : p
  end


  def get_probability(eng_word)
    translations = delete_endings(translate(eng_word))

    puts "Translations without endings:"
    puts translations.join(", ")
    puts

    probability = {}

    @rus_sentence.each { |actual_word|
      probability[actual_word] = 0.0
      translations.each do |translation|
        p = calc_probability(actual_word, translation)
        puts "probability: #{p}, actual word: #{actual_word}, translation: #{translation}"
        probability[actual_word] = p if probability[actual_word] < p
      end
    }

    puts
    puts "Probability for translations of word \"#{eng_word}\":"
    probability.each { |key, value| puts "#{key}: #{value.round(3)}" }

    probability
  end


  def translate(eng_word) # here call to Max's ending code
    # this is stub method
    case eng_word
      when 'street'
        return %w(улица ул стрит дорожка след проход коридор)
      when 'people'
        return %w(нация население жители родители люди родные свита команда рабы народ)
      when 'are'
        return %w(ар это быть являются находиться происходить случаться)
      when 'walking'
        return %w(ходьба походка хождение гулянье пробежка движение обход)
      else
        return []
    end
  end

end


my_translation = MatchTranslation.new("People are walking on the street", "Люди гуляют на улице")
puts "probability:"
puts my_translation.calc_probability("улиц", "умниц")
puts my_translation.calc_probability("бежать", "бегут")
puts my_translation.calc_probability("беж", "бег")


puts "probability for all words"
hash = my_translation.get_probability("street")
hash.each { |key, value| puts "p: #{key} word: #{value}" }
