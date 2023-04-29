class Translator
  def initialize(words_file, grammar_file)
    @posTable = Hash.new {|h,k| h[k] = [] }
  
    @grammarSyntax = []
    updateLexicon(words_file)
    updateGrammar(grammar_file)
  end
  #Inner Class Word 
  class Word
    def initialize(word, adjective)
      @word = word 
      @pos  = adjective 
      @hash = {}
    end

    def getPos()
      @pos
    end 

    def getWord()
      @word
    end

    def addTranslation(language,word)
      @hash[language] = word
    end

    def translate(language)
      @hash.fetch(language)
    end

    def hasTranslation(language)
      @hash.has_key?(language)
    end

    def wordExist(word)
      @hash.has_value?(word)
    end
  end

  class Grammar
    def initialize(language,words,restrictions)
      @language = language
      @hash = restrictions
      @words = words
    end

    def getLanguage
      @language
    end

    def getwords
      @words
    end

    def getRestrictions
      @hash
    end

    def updateSyntax(arr)
      @words = arr
    end
  end

  # part 1

  def hasWord(word,pos)
    @posTable.each do |key, value|
      value.each_with_index do |w, index|
        return index if  w.getWord == word && w.getPos == pos
      end
    end
    -1 # word not found
  end

  def checkPos(word, pos)
    if @posTable.has_key?(pos)
      @posTable[pos].each do |w|
        return true if w.wordExist(word)==true
      end
    end
    false
  end


  
  def updateLexicon(inputfile)
    File.readlines(inputfile).each do |line|
      pattern = /^([a-z]+(?:-[a-z]+)*),\s([A-Z]{3}),\s*(?:[A-Z][a-z0-9]+:[a-z]+(?:-[a-z]+)*(?:,\s*[A-Z][a-z0-9]+:[a-z]+(?:-[a-z]+)*)*)$/
      matches = line.match(pattern)
      if matches
        word = matches[1]
        pos = matches[2]
        #hash = {}
        x = hasWord(word,pos)
        if x == -1
          wordObj = Word.new(word,pos)
          wordObj.addTranslation("English",word)
        end
        line.scan(/([A-Z][a-z0-9]+):([a-z]+(?:-[a-z]+)*)/) do |key, value|
          #hash[key] = value
          if x != -1
            @posTable[pos][x].addTranslation(key,value)
          else
            wordObj.addTranslation(key,value)
          end
        end
        if x==-1
          @posTable[pos].push(wordObj)
        end
      end
    end
  end  
  
  def updateGrammar(inputfile)
    File.readlines(inputfile).each do |line|
      regex = /^([A-Z][a-z0-9]+)\s*:\s*(([A-Z]+)(?:\{(\d+)\})?(?:\s*,\s*([A-Z]+)(?:\{(\d+)\})?)*)/
      if line =~ regex
        match = line.match(regex)
        language = match[1]
        words = match[2].split(", ")
        pos = []
        word_numbers = {}
        words.each do |word|
          if word =~ /([A-Z]+)\{(\d+)\}/
            word_numbers[$1] = $2.to_i
            pos.push($1)
          elsif word =~ /([A-Z]+)/
            pos.push($1)
          end
        end
        if containsSyntax(language) != -1
          @grammarSyntax[containsSyntax(language)].updateSyntax(words)
        else 
          grammarObj = Grammar.new(language,pos,word_numbers)
          @grammarSyntax.push(grammarObj)
        end 
      end
    end
  end


  # part 2  

  #Helper Method to check if the syntax for a language exists 
  def containsSyntax(language)
    for i in 0..@grammarSyntax.length-1
      if @grammarSyntax[i].getLanguage == language
        return i
      end
    end
    return -1 
  end
  #This method iterates through the posTable and returns a word in that language
  def getPosWord(pos,language)
    arr = []
    for word in @posTable[pos]
      if word.hasTranslation(language)
        arr.push(word.translate(language))
      end
    end
    return arr
  end 
  def languageExists(language)
    @posTable.each do |key,value|
      value.each do |word|
        return true if word.hasTranslation(language) == true
      end
    end
    return false 
  end
  def generateSentence(language, struct)
    #Returns nil if either language or struct is empty
    return nil if language.empty? || struct.empty? 
    return nil if languageExists(language) == false
    #returns nil if struct is not an array or struct not found 
    return nil if !struct.kind_of?(Array) && containsSyntax(struct) == -1
    str = "" 
    #Checking if the struct is Array 
    if (struct.kind_of?(Array)) 
      for pos in struct
        arr = getPosWord(pos,language)
        return nil if arr.empty?
        wd = arr[0]
        str += wd
        str += " "
        arr.shift
      end
    else 
      index = containsSyntax(struct)
      return nil if index == -1
      structArray = @grammarSyntax[index].getwords
      for pos in structArray
        arr = getPosWord(pos,language)
        return nil if arr.empty?
        if @grammarSyntax[index].getRestrictions.has_key?(pos)
          count = [@grammarSyntax[index].getRestrictions[pos],arr.length].min
          tempStr = arr.sample(count).join(" ")
          str += tempStr + " "
        else
          wd = arr.sample
          str += wd
          str += " "
        end 
      end
    end
    str.rstrip
  end
  
  def checkGrammar(sentence, language) 
    arr = sentence.split(" ")
    i = containsSyntax(language)
    return false if arr.length == 0 || i == -1
    arrIndex = 0
    posArray = @grammarSyntax[i].getwords
    for pos in posArray
      if @grammarSyntax[i].getRestrictions.has_key?(pos)
        count = 0
        while count < @grammarSyntax[i].getRestrictions[pos]
            bool = checkPos(arr[arrIndex],pos)
            if bool == false && count == 0
              return false
            elsif bool == false && count > 0
              count = @grammarSyntax[i].getRestrictions[pos]
              arrIndex -= 1
            else 
              count+=1
              arrIndex += 1
            end
        end
      else
        if checkPos(arr[arrIndex],pos) == false
          return false
        end
        arrIndex += 1
      end
    end
    true
  end
  
  # Remember to return nil when sentence cannot be formed
  def changeGrammar(sentence, struct1, struct2)
    return nil if sentence.empty? || struct1.empty? || struct2.empty?
    return nil if !sentence.kind_of?(String) || (!struct1.kind_of?(Array) && containsSyntax(struct1) == -1) || (!struct2.kind_of?(Array) && containsSyntax(struct2) == -1)
    arr = sentence.split(" ")
    if struct1.kind_of?(Array)
      struct1Arr = struct1
    else 
      i = containsSyntax(struct1)
      struct1Arr = @grammarSyntax[i].getwords
    end
    if struct2.kind_of?(Array)
      struct2Arr = struct2
    else 
      i = containsSyntax(struct2)
      struct2Arr = @grammarSyntax[i].getwords
    end
    hash = Hash.new {|h,k| h[k] = []}
    arrIndex = 0
    for pos in struct1Arr
        hash[pos].push(arr[arrIndex])
        arrIndex += 1 
    end
    str = ""
    for pos in struct2Arr
      return nil if !hash.has_key?(pos) || hash[pos].empty?
      wd = hash[pos][0]
      hash[pos].shift
      str = str + wd + " "
    end
    str.rstrip
  end

  # part 3
  def getTranslatedWord(word, language)
    @posTable.each do |key,value|
      value.each do |w|
        return w.translate(language) if w.wordExist(word) && w.hasTranslation(language)
      end
    end
    nil
  end 
  def changeLanguage(sentence, language1, language2)
    arr = sentence.split(" ")
    translatedArr = []
    str = ""
    for word in arr
      t = getTranslatedWord(word,language2)
      return nil if t == nil
      str += t
      str += " "
    end
    str.rstrip
  end
  
  def translate(sentence, language1, language2)
    #Checking valid paramaters
    return nil if sentence.empty? || language1.empty? || language2.empty?
    arr = sentence.split(" ")
    i = containsSyntax(language1)
    j = containsSyntax(language2)
    return nil if i == -1 || j == -1
    struct1 = @grammarSyntax[i].getwords
    struct2 = @grammarSyntax[j].getwords
    
    hash = Hash.new{|h,k| h[k] = []}
    arrIndex = 0
    
    for pos in struct1
      return nil if checkPos(arr[arrIndex],pos) == false
      if @grammarSyntax[i].getRestrictions.has_key?(pos)
        count = 0
        loop = [@grammarSyntax[i].getRestrictions[pos],arr.length].min
        while count < loop
          if checkPos(arr[arrIndex],pos) == false && count > 0
            count = @grammarSyntax[i].getRestrictions[pos]
          else
            hash[pos].push(arr[arrIndex])
            count += 1
            arrIndex += 1
          end
        end
      else 
        hash[pos].push(arr[arrIndex])
        arrIndex += 1
      end
    end
    
    str = ""
    for pos in struct2
      return nil if !hash.has_key?(pos) || hash[pos].empty?
      if @grammarSyntax[j].getRestrictions.has_key?(pos)
        count = 0
        tempStr = ""
        loop = [@grammarSyntax[j].getRestrictions[pos],hash[pos].length].min
        while count < loop
          temp = hash[pos][0]
          translation = getTranslatedWord(temp,language2)
          return nil if translation ==nil
          hash[pos].shift
          tempStr += translation + " "
          count +=1
        end
        str += tempStr
      else 
        temp = hash[pos][0]
        translation = getTranslatedWord(temp,language2)
        return nil if translation == nil
        hash[pos].shift
        str += translation 
        str += " "
      end
    end
    str.rstrip
  end

  def getGrammarSyntax()
    for i in @grammarSyntax
      puts i.getLanguage
      for j in i.getwords
        puts j + ","
      end
    end
  end

  def getPosTable()
    puts @posTable
  end
end
