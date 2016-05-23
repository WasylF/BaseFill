#coding utf-8
require 'unicode'
require 'csv'
require_relative 'multitran'
require_relative 'file_parser'

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

Translation = Struct.new(:rus_index, :translation)

class MatchTranslation

  BAD_TRANSLATION = 'bad translation'
  MIN_PROBABILITY = 0.7 #minimum probability for right translation

  # constructor
  # eng_sentence - english sentence from Excel
  # rus_sentence - russian sentence from Excel
  def initialize(eng_sentence, rus_sentence)
    eng_sentence.each { |word| word.downcase!.force_encoding(Encoding::UTF_8) }
    rus_sentence.each { |word| word.downcase!.force_encoding(Encoding::UTF_8) }
    @eng_sentence = eng_sentence
    @rus_sentence = rus_sentence
    # eng_sentence.downcase!
    # rus_sentence.downcase!

    # eng_sentence.force_encoding(Encoding::UTF_8)
    # rus_sentence.force_encoding(Encoding::UTF_8)

    # @eng_sentence = eng_sentence.split(' ')
    # @rus_sentence = rus_sentence.split(' ')

    # TODO: add words
    @useless_eng_words = %w(a the an on in by is are am were was be been have has had to i you he she it we they)
    @useless_rus_words = %w(а б бы в во на я ты он она оно мы вы они)

    @rus_endings = %w(am ax cm ex а ам ами ас ая е ев ей ем еми емя ею её и ие ий им ими ит ите их ишь ию ия иям иями иях м ми мя о ов ого ое ой ом ому ою оё у ум умя ут ух ую ют шь ю я ям ями ях ёй ёт ёте ёх ёшь)

    delete_useless!

    @used_rus = Array.new(@rus_sentence.length, false)
    @used_eng = Array.new(@eng_sentence.length, false)

    @translation_eng_to_rus = Array.new(@eng_sentence.length)

    @rus_infinitives = get_infinitives(@rus_sentence)
    @rus_sentence = delete_endings(@rus_sentence)

    @all_translations = {}
    @eng_sentence.each { |eng_word|
      @all_translations[eng_word] = translate(eng_word)
    }
  end


  # deletes useless words in russian and english sentences
  def delete_useless!
    @eng_sentence = @eng_sentence - @useless_eng_words
    @rus_sentence = @rus_sentence - @useless_rus_words
  end


  # deletes endings in russian words (if possible)
  def delete_endings(words)
    without_endings = []
    words.each do |word|
      without_endings << delete_ending(word)
    end

    without_endings
  end


  # deletes ending in one russian word (if possible)
  def delete_ending(word)
    word_size = word.size
    if word_size <= 3
      return word
    else
      3.downto(1).each do |i|
        ending = word.last(i)
        if @rus_endings.include?(ending)
          return word[0, word_size - i]
        end
      end
    end

    word
  end


  # calculates levenshtein distance between words (russian words in our case)
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


  # calculates probability of right translation
  def calc_probability(actual_word, translation_word)
    d = levenshtein_distance(actual_word, translation_word)

    #puts "distance: #{d}"
    #puts "length: #{actual_word.size}"
    #puts "p: #{d * 1.0 / actual_word.size}"
    min_leng= actual_word.size < translation_word.size ? actual_word.size : translation_word.size
    p = 1.0 - d * 1.0 / min_leng
    p < 0 ? 0.0 : p
  end


  # returns best translation for eng_word
  def get_best_translation(eng_word)
    translations = @all_translations[eng_word]

    rus_size= @rus_sentence.length - 1
    best= ""
    p_best= -1
    rus_index= -1
    (0..rus_size).each { |i|
      unless @used_rus[i]
        sentence_word= @rus_sentence[i]
        translations.each do |translation|
          p = calc_probability(sentence_word, delete_ending(translation))
          if p > p_best
            p_best = p
            best = translation
            rus_index = i
          end
        end
      end
    }

    if p_best > MIN_PROBABILITY
      @used_rus[rus_index] = true
      return best
    end
    BAD_TRANSLATION
  end


  # returns translations of eng_word (from multitran)
  def translate(eng_word) # here call to Max's ending code
    Multitran.translate(eng_word).map { |t| t[0] }
  end


  # returns infinitives of rus_words (from yandex's tool)
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
    infinitives
  end

  # matches eng words to russian if one of translation is an infinitive of some russian word
  # result stored in @translation_eng_to_rus field
  def match_words_yandex
    eng_size= @eng_sentence.length - 1
    collision= false
    updated= false

    (0..eng_size).each { |eng_index|
      if !@used_eng[eng_index]
        eng_word= @eng_sentence[eng_index]
        translations= @all_translations[eng_word]
        rus_indexes= []
        translations.each { |translation|
          rus_indexes+= matches_infinitives(translation)
        }
        rus_indexes.uniq!
        if rus_indexes.size == 1
          updated= true
          @used_eng[eng_index]= true
          @used_rus[rus_indexes[0].rus_index]= true
          @translation_eng_to_rus[eng_index]= rus_indexes[0].translation
        else
          collision|= rus_indexes.size > 1
        end
      end
    }

    if collision && updated
      match_words_yandex
    end
  end

  # return indexes of russian words in sentence if translation matches to it infinitive,
  # empty otherwise
  def matches_infinitives(translation)
    rus_size= @rus_infinitives.length - 1
    rus_indexes= []

    translation.force_encoding(Encoding::UTF_8)
    (0..rus_size).each { |i|
      unless @used_rus[i]
        if @rus_infinitives[i].include?(translation)
          rus_indexes[rus_indexes.size]= Translation.new(i, translation)
        end
      end
    }

    rus_indexes
  end

  # try to match every english word from sentence to one russian word
  # return hash{key:"eng word", value: "russian infinitive (from multitran)"}
  def process_sentences
    match_words_yandex
    result= {}
    eng_size= @eng_sentence.length - 1

    (0..eng_size).each { |eng_index|
      if @used_eng[eng_index]
        @translation_eng_to_rus[eng_index].force_encoding(Encoding::UTF_8)
        result[@eng_sentence[eng_index]]= @translation_eng_to_rus[eng_index]
      else
        translation= get_best_translation(@eng_sentence[eng_index])
        if translation != BAD_TRANSLATION
          @used_eng[eng_index]= true
          result[@eng_sentence[eng_index]]= translation
        end
      end
    }

    result
  end
end

#eng= %w(I gathered in this infographic 15 most practical advice for men who would like to always look perfectly This is a real man's guide to style Read remember and act)
#rus= %w(собрал в этой инфографике 15 самых дельных советов для мужчин которые бы хотели всегда выглядеть на отлично Это настоящий гид по мужскому стилю Читайте запоминайте и действуйте)

#rus= %w(Мы нуждаемся в использовании нескольких режимов)
#eng= %w(We need to use several modes)

rus= %w(В этой статье я вкратце расскажу вам о процессах потоках и об основах многопоточного программирования на языке Java)
eng= %w(In this article I will briefly tell you about the processes flows and the basics of multithreaded programming in Java)
my_translation = MatchTranslation.new(eng, rus)

#words = FileParser.parse('file2.csv')
#my_translation = MatchTranslation.new(words[1][0], words[1][1])

matches = my_translation.process_sentences
matches.each { |key, value| puts "eng_word: #{key}   -   rus_word: #{value}" }