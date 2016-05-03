#coding utf-8
require 'unicode';

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


  def initialize(engSentence, rusSentence)
    engSentence= engSentence.downcase
    rusSentence= rusSentence.downcase


    @engSentence= engSentence.split(' ')
    @rusSentence= rusSentence.split(' ')

    @uselessEngWords= ['a', 'the', 'an', 'on', 'in', 'by']
    @uselessRusWords= ['а', 'б', 'бы', 'в', 'во', 'на']

    @rusEndings= ['am', 'ax', 'cm', 'ex', 'а', 'ам', 'ами', 'ас', 'ая', 'е', 'ев', 'ей', 'ем', 'еми', 'емя', 'ею', 'её', 'и', 'ие', 'ий', 'им', 'ими', 'ит', 'ите', 'их', 'ишь', 'ию', 'ия', 'иям', 'иями', 'иях', 'м', 'ми', 'мя', 'о', 'ов', 'ого', 'ое', 'ой', 'ом', 'ому', 'ою', 'оё', 'у', 'ум', 'умя', 'ут', 'ух', 'ую', 'ют', 'шь', 'ю', 'я', 'ям', 'ями', 'ях', 'ёй', 'ёт', 'ёте', 'ёх', 'ёшь']

    deleteUseless
    @rusSentence= deleteEndings(@rusSentence)
  end


  def deleteUseless()
    engS= []
    @engSentence.each do |word|
      if !@uselessEngWords.include?(word)
        engS.push word
      end
    end
    @engSentence= engS

    rusS= []
    @rusSentence.each do |word|
      if !@uselessRusWords.include?(word)
        rusS.push word
      end
    end
    @rusSentence= rusS
  end


  def deleteEndings(words)
    withoutEndings= []
    words.each do |word|
      l= word.size
      puts "word: #{word},   size: #{l}"
      if (l<=3)
        withoutEndings << word
      else
        flag= false
        for i in (3).downto(1)
          s= word.last(i)
          puts "word: #{word}    ending:  #{s}"
          if @rusEndings.include?(s)
            withoutEndings << word[0, l-i]
            flag= true
            break;
          end
        end
        puts flag.to_s
        if !flag
          withoutEndings << word
        end
      end

    end

    puts withoutEndings.join(', ')
    return withoutEndings
  end


  def levenshtein_distance(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m+1) { Array.new(n+1) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i-1] == t[j-1] # adjust index into string
                    d[i-1][j-1] # no operation required
                  else
                    [d[i-1][j]+1, # deletion
                     d[i][j-1]+1, # insertion
                     d[i-1][j-1]+1, # substitution
                    ].min
                  end
      end
    end

    return d[m][n]
  end


  def calcProbability(actualWord, translationWord)
    d= levenshtein_distance(actualWord, translationWord)
    #puts "distance: #{d}"
    #puts "length: #{actualWord.size}"
    #puts "p: #{d*1.0/actualWord.size}"

    p= 0.0
    if (d==0)
      p= 1.0
    else
      p= 1.0 - d*1.0/actualWord.size
    end

    if (p<0)
      p= 0.0
    end

    return p
  end


  def getProbability(engWord)
    translations_= getTranslations(engWord)
    translations= deleteEndings(translations_)

    puts "translations without endings:"
    puts translations.join(", ")
    puts "\n"

    probability= {}

    @rusSentence.each { |actualWord|
      probability[actualWord]= 0.0
      translations.each do |transl|
        p= calcProbability(actualWord, transl)
        puts "p: #{p} actual word: #{actualWord}  translation: #{transl}"
        if (probability[actualWord]<p)
          probability[actualWord]= p
        end
      end
    }


    puts "\n\nprobability for translations of word \"#{engWord}\":\n"
    probability.each do |key, value|
      puts "#{key}:#{value}"
    end

    return probability
  end


  def getTranslations(engWord) # here call to Max's code
    # this is stub method
    case engWord
      when 'street'
        return ['улица', 'ул', 'стрит', 'дорожка', 'след', 'проход', 'коридор']
      when 'people'
        return ['нация', 'население', 'жители', 'родители', 'люди', 'родные', 'свита', 'команда', 'рабы', 'народ']
      when 'are'
        return ['ар', 'это', 'быть', 'являются', 'находиться', 'происходить', 'случаться']
      when 'walking'
        return ['ходьба', 'походка', 'хождение', 'гулянье', 'пробежка', 'движение', 'обход']
    end

    return []
  end

end


myTranslation= MatchTranslation.new("People are walking on the street", "Люди гуляют на улице")
puts "probability:"
puts myTranslation.calcProbability("улиц", "умниц")
puts myTranslation.calcProbability("бежать", "бегут")
puts myTranslation.calcProbability("беж", "бег")


puts "probability for all words"
hash= myTranslation.getProbability("street").to_s
