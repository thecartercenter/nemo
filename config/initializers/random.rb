class Random
  LETTERS = %w{a b c d e f g h i j k l m n o p q r s t u v w x y z}
  
  def self.words(size = 1)
    Random.paragraphs.split(" ")[0,size].join(" ").gsub(/[,;?\.'"\-\n]/, "").downcase
  end
  
  def self.phrase(size = 3)
    words(size).capitalize
  end
  
  def self.question(size = 8)
    words(size).capitalize + "?"
  end
  
  def self.sentence(size = 12)
    words(size).capitalize + "."
  end
  
  def self.phone_num
    phone[0,12]
  end
  
  def self.letters(size = 8)
    (0...size).map{LETTERS[rand(LETTERS.size)]}.join
  end
end