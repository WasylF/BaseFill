require 'open-uri'
require 'nokogiri' #TODO: remove

class Multitran
  def self.translate(word)
    url = "http://www.multitran.ru/c/m.exe?l1=1&l2=2&s=#{word}"
    html = open(url)

    doc = Nokogiri::HTML(html)

    translated_words = []
    part_of_speech = nil
    # doc.css('table table:nth-child(5) td:not([bgcolor]) > a:not([title]):not([href="#start"]), table table:nth-child(5) td > em').each do |node|
    doc.css('table table:nth-child(5) td:not([bgcolor]) a:not([title]):not([href="#start"]), table table:nth-child(5) td > em').each do |node|
      if node.name == 'em'
        part_of_speech = node.text
      else
        translated_words << [node.text.strip, part_of_speech]
      end
    end

    translated_words
  end
end
