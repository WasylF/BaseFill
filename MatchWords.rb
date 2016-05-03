class MatchTranslation


  def initialize(engSentence, rusSentence)
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


end