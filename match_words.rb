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

  @bad_translation = 'bad translation'

  def initialize(eng_sentence, rus_sentence)
    eng_sentence.downcase!
    rus_sentence.downcase!

    eng_sentence.force_encoding(Encoding::UTF_8)
    rus_sentence.force_encoding(Encoding::UTF_8)

    @eng_sentence = eng_sentence.split(' ')
    @rus_sentence = rus_sentence.split(' ')

    # TODO: add words
    @useless_eng_words= %w(a the an on in by is are am were was be been have has had)
    @useless_rus_words= %w(а б бы в во на)

    @rus_endings = %w(am ax cm ex а ам ами ас ая е ев ей ем еми емя ею её и ие ий им ими ит ите их ишь ию ия иям иями иях м ми мя о ов ого ое ой ом ому ою оё у ум умя ут ух ую ют шь ю я ям ями ях ёй ёт ёте ёх ёшь)

    delete_useless!

    puts "eng_sentence: #{@eng_sentence.join(", ")}"
    puts "rus_sentence: #{@rus_sentence.join(", ")}"

    @used_rus= Array.new(@rus_sentence.length, false)
    @used_eng= Array.new(@eng_sentence.length, false)

    @translation_eng_to_rus = Array.new(@eng_sentence.length)

    @rus_infinitives= get_infinitives(@rus_sentence)
    @rus_sentence = delete_endings(@rus_sentence)

    @all_translations= {}
    @eng_sentence.each { |eng_word|
      @all_translations[eng_word]= translate(eng_word)
    }
  end


  def delete_useless!
    new_eng_sentence = @eng_sentence - @useless_eng_words
    new_rus_sentence = @rus_sentence - @useless_rus_words

    puts "Useless English words: #{(@eng_sentence - new_eng_sentence).join(', ')}"
    puts "Useless Russian words: #{(@rus_sentence - new_rus_sentence).join(', ')}"

    @eng_sentence = new_eng_sentence
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

  def delete_ending(word)
    word_size = word.size
    if word_size <= 3
      puts "word: #{word}, size: #{word_size}"
      return word
    else
      3.downto(1).each { |i|
        ending = word.last(i)
        if @rus_endings.include?(ending)
          puts "word: #{word}, ending: #{ending}"
          return word[0, word_size - i]
        end
      }
    end

    word
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
    translations = delete_endings(@all_translations[eng_word])

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


  def get_best_translation(eng_word)
    translations = @all_translations[eng_word]

    rus_size= @rus_sentence.length - 1
    best= ""
    p_best= -1
    (0..rus_size).each { |i|
      if !@used_rus[i]
        sentence_word= @rus_sentence[i]
        translations.each do |translation|
          p = calc_probability(sentence_word, delete_ending(translation))
          if p > p_best
            p_best= p
            best= translation
          end
        end
      end
    }

    p_best > 0.5 ? best : @bad_translation
  end

  def translate(eng_word) # here call to Max's ending code
    # this is stub method
    case eng_word
      when 'street'
        return %w(улица ул стрит дорожка след проход коридор)
      when 'people'
        return %w(нациянаселение жители родители люди родные свита команда рабы народ)
      when 'are'
        return %w(ар это быть являются находиться происходить случаться)
      when 'walking'
        return %w(ходьба походка хождение гулянье пробежка движение обход гулять)
      else
        return []
    end
  end


  def get_infinitives(rus_words)
    shell_output = ""
    IO.popen('mystem.exe -nl', 'r+') do |pipe|
      rus_words.each { |word|
        pipe.puts (word)
      }
      pipe.close_write

      shell_output = pipe.read
    end

    shell_output.force_encoding(Encoding::UTF_8)

    result= shell_output.split("\n")
    i= 0
    infinitives= Array.new(@rus_sentence.length) { Array.new(0) }
    result.each { |inf|
      infinitives[i]= inf.split('|')
      i+= 1
    }
    return infinitives
  end


  def match_words
    eng_size= @eng_sentence.length - 1

    (0..eng_size).each { |eng_index|
      eng_word= @eng_sentence[eng_index]
      translations= @all_translations[eng_word]
      translations.each { |translation|
        rus_index= matches_infinitive(translation)
        if rus_index >= 0
          @used_eng[eng_index]= true
          @translation_eng_to_rus[eng_index]= translation
        end
      }
    }
  end


  def matches_infinitive(translation)
    rus_size= @rus_infinitives.length - 1

    translation.force_encoding(Encoding::UTF_8)
    (0..rus_size).each { |i|
      if !@used_rus[i]
        if @rus_infinitives[i].include?(translation)
          @used_rus[i]= true
          return i
        end
      end
    }

    return -1
  end


  def process_sentences
    match_words
    result= {}
    eng_size= @eng_sentence.length - 1

    (0..eng_size).each { |eng_index|
      if @used_eng[eng_index]
        @translation_eng_to_rus[eng_index].force_encoding(Encoding::UTF_8)
        result[@eng_sentence[eng_index]]= @translation_eng_to_rus[eng_index]
      else
        translation= get_best_translation(@eng_sentence[eng_index])
        if translation!=@bad_translation
          result[@eng_sentence[eng_index]]= translation
        end
      end
    }

    result
  end

end


my_translation = MatchTranslation.new("People are walking on the street", "Люди гуляют на улице")
puts "probability:"
puts my_translation.calc_probability("улиц", "умниц")
puts my_translation.calc_probability("бежать", "бегут")
puts my_translation.calc_probability("беж", "бег")


puts "probability for all words"
hash = my_translation.get_probability("street")
hash.each { |key, value| puts "word: #{key} probability: #{value}" }

infinitives= my_translation.get_infinitives(%w(Машины люди телефончик компьютеров дорогам прибежавший))

infinitives.each { |infinitive|
  puts "inf:"
  infinitive.each { |inf| puts inf }
}

infinitives= my_translation.get_infinitives(%w(Люди гуляют улице))

infinitives.each { |infinitive|
  puts "inf:"
  infinitive.each { |inf| puts inf }
}

puts '#######################################'
puts '#######################################'
puts '#######################################'

matches= my_translation.process_sentences
matches.each { |key, value| puts "eng_word: #{key}, rus_word: #{value}" }
