require 'gtk2'
require 'pp'
require 'pry'
require 'yaml'

CONSTANT = YAML.load_file(File.open('constants.yaml', 'r'))
ATCH = [Gtk::EXPAND | Gtk::FILL, Gtk::SHRINK, 0, 0].freeze
Gtk::RC.parse_string(<<-EOF)
style "combocrap" {
  GtkComboBox::appears-as-list = 1
  GtkComboBox::arrow-size = 5
}
class "GtkComboBox" style "combocrap"
EOF

class Application
  attr_reader :notebook, :windows 
  def load
  end

  def save
    pp @a
  end

  def gettotem
    @a.gettotem
  end
  
  def spelllvl(name,value)
    @notebook.spell.spelllvl(name,@a.spelllvl(name.to_sym,value))
    updatespellpoints
  end

  def removespell(name)
    @a.removespell(name.to_sym)
    @notebook.spell.removespell(name)
    updatespellpoints
  end

  def appendspell(name,category,subcategory)
    if @a.appendspell(name.to_sym,category.to_sym,subcategory ? subcategory.to_sym : nil)
      @notebook.spell.appendspell(name,category,subcategory)
    end
  end

  def checkspells(totem)
    if @a.getmagetype =~ /ist/
      if totem
        enablespells(totem)
      else
        disablespells
      end
    end
  end

  def dialogchoose(stuff,type)
    a = nil
    dialog=Gtk::Dialog.new("Choose Boni",@windows,Gtk::Dialog::MODAL,
                           [stuff[0].join(" : "),0],
                           [stuff[1].join(" : "),1])
    dialog.run do |response|
      response == 0 ? a=stuff[0] : a=stuff[1]
      dialog.destroy
    end
    a
  end

  def choosespells(spells)
    chos = spells.collect {|x| x if x[0] == :Choose}.compact
    fixed = spells - chos
    [dialogchoose(chos.flatten(1)[1],"spells")] + fixed
  end

  def choosespirits(spirits)
    chos = spirits.collect {|x| x if x[0] == :Choose}.compact
    fixed = spirits - chos
    [dialogchoose(chos.flatten(1)[1],"spirits")] + fixed
  end

  def settotem(totem,group)
    boni = nil
    if totem
      boni = {:spells => nil, :spirits => nil}
      short = CONSTANT[:totems][group][totem]
      if short[:spells] && (short[:spells].flatten(1).include? :Choose)
        boni[:spells] = choosespells(short[:spells])
      else
        boni[:spells] = short[:spells]
      end
      if short[:spirits] && (short[:spirits].flatten(1).include? :Choose)
        boni[:spirits] = choosespirits(short[:spirits])
      else
        boni[:spirits] = short[:spirits]
      end
    end
    @tooltips.set_tip(@windows,"",nil)
    @a.settotem(totem,group,boni)
    totem = gettotem ? gettotem[0] : nil
    checkspells(totem)
#    @guiattributes.nototem unless totem
  end

  def availabletotems(group)
    if @a.getmagetype =~ /ist/
      @guiattributes.availabletotems(
        CONSTANT[:totems][group].collect {|x| x[0] if x[1][:spells]}.compact)
    else
      @guiattributes.availabletotems(
        CONSTANT[:totems][group].each_key)
    end
  end

  def checkskills(attr,value,oldvalue,check=0)
    @a.checkskills(attr,value,oldvalue,check)
    setpointsrem
  end

  def skilllvl(skill,value)
    @notebook.skill.skilllvl(skill,@a.skilllvl(skill,value.value))
    setpointsrem
  end

  def delskill(skill)
    @a.delskill(skill[1])
    @notebook.skill.delskill(skill[1])
    setpointsrem
  end

  
  def addskill(attr,skill,special)
    @notebook.skill.addskill(@a.addskill(attr,skill,special))
    setpointsrem
  end

  def updatepools
    CONSTANT[:derived][:Pools].each do |x|
      @guiattributes.updatepool(x,@a.updatepool(x))
    end 
  end

  def metachecks(metatype)
    meta = CONSTANT[:metatypes][getmetatype]
    @basic.checkage(@a.checkage,meta)
    @basic.checkweight(@a.checkweight,meta)
    @basic.checkheight(@a.checkheight,meta)
  end

  def updatereaction
    @guiattributes.updatereaction(@a.updatereaction)
    @guiattributes.updateinitiative(@a.updateinitiative)
  end

  def setattribute(attr, value)
    @guiattributes.setattribute(attr, @a.setattribute(attr, value.value))
    updateattr(attr)
    setpointsrem
  end

  def setname(name)
    @basic.setname(@a.setname(name.text))
  end

  def setstreetname(sname)
    @basic.setstreetname(@a.setstreetname(sname.text))
  end

  def setage(age)
    @basic.setage(@a.setage(age.value))
  end

  def setgender(gender)
    @basic.setgender(@a.setgender(gender))
  end

  def setmetatype(metatype)
    @basic.setmetatype(@a.setmetatype(metatype))
    setmetamods
    setpointsrem
  end

  def enablespells(totem=nil)
    @notebook.get_nth_page(3).sensitive=true
    if totem
      tot,grp,boni = @a.gettotem
      spells = boni[:spells].collect  {|x| x[0] if x[1] > 0}.compact
    else
      spells=CONSTANT[:spelltypes].keys
    end
    @notebook.spell.enablespells(spells)
  end

  def disablespells
    @notebook.spell.clear
    @notebook.get_nth_page(3).sensitive=false
  end

  def setmagetype(magetype)
    @basic.setmagetype(@a.setmagetype(magetype))
    setpointsrem
    setmagic
    setspellpoints
    @a.getmagic && @a.getspellpoints > 0 && 
      !(@a.getmagetype =~ /^[^F].*ist|Conj/) ? enablespells : disablespells
    @a.getmagetype =~ /Shaman/ ? enabletotem : disabletotem
    if @a.getmagetype == :Shamanist
      @tooltips.set_tip(@windows,"Select a totem to be able to select spells",nil)
    else
      @tooltips.set_tip(@windows,"",nil)
    end
  end

  def enabletotem
    @guiattributes.enabletotem
  end

  def disabletotem
    @guiattributes.disabletotem
  end

  def setnuyen(nuyen)
    @basic.setnuyen(@a.setnuyen(nuyen))
    setnuyenrem
    setpointsrem
  end

  def setheight(height)
    @basic.setheight(@a.setheight(height.value))
  end

  def setweight(weight)
    @basic.setweight(@a.setweight(weight.value))
  end

  def setnuyenrem
    @basic.setnuyenrem(@a.getnuyenrem)
    setpointsrem
  end

  def setpointsrem
    @basic.setpointsrem(@a.getpointsrem)
  end

  def setspellpoints
    @guiattributes.setspellpoints(@a.setspellpoints)
  end

  def updatespellpoints
    @guiattributes.setspellpoints(@a.getspellpoints)
  end

  def setmetamods
    @a.setmetamods
  end

  def updateattr(attr)
    @guiattributes.updateattr(attr, @a.updateattr(attr))
    updatepools if [:Quickness,:Intelligence,:Willpower].include? attr
    updatereaction if [:Quickness,:Intelligence].include? attr
  end

  def setmagic
    @guiattributes.setmagic(@a.setmagic)
    updatepools
    updatereaction
  end

  def getmetatype
    @a.getmetatype
  end

  def initialize
    @windows = Gtk::Window.new
    @tooltips = Gtk::Tooltips.new
    @a = Character.new(self)
    @guiattributes = Attributeblock.new(self)
    @tooltips.set_tip(@guiattributes,"Set attribute values, select totem if shaman",nil)
    @basic = Mainblock.new(self)
    @tooltips.set_tip(@basic,"Input name and such, choose race/magetype from dropdown menus",nil)
    @notebook = Notebook.new(self)
    @tooltips.set_tip(@notebook,"Choose skills, spells if magetype with spellpoints, cyberware and gear in tabs",nil)
    @table = Gtk::Table.new(13, 12, homogenous = false)
    @windows.add(@table)
    updatepools
    updatereaction
    @table.attach @guiattributes, 0, 3, 4, 12
    @table.attach @basic, 0, 13, 0, 4, *ATCH
    @table.attach @notebook, 3, 13, 4, 12
    @table.n_columns = 13
    @table.n_rows = 12
    @windows.show_all
    @windows.signal_connect('destroy') {Gtk.main_quit}
    # binding.pry
    Gtk.init
    Gtk.main
  end
end

class Character
  attr_reader :name, :streetname, :age, :attributes,
              :points, :metatype, :magetype, :gender
  def setname(name)
    @name = name
  end

  def setstreetname(sname)
    @streetname = sname
  end

  def setage(age)
    @age = age
  end

  def setgender(gender)
    @gender = gender.active_text
    gender.active
  end

  def setheight(height)
    @height = height
  end
  
  def gettotem
    @totem
  end

  def spelllvl(name,value)
    if value > @spells[name][1]
      if value - @spells[name][1] < @spellpoints
        @spellpoints -= value - @spells[name][1]
        @spells[name][1] = value
      end
    else
      @spellpoints += @spells[name][1] - value
      @spells[name][1] = value
    end
    @spells[name][1]
  end


  def appendspell(name,category,subcategory)
    if @spellpoints > 0
      @spells[name] = [
        (subcategory ? CONSTANT[:spelltypes][category][subcategory][name] :
                     CONSTANT[:spelltypes][category][name]),1]
      @spellpoints -= 1
      @app.updatespellpoints
    else
      nil
    end
  end

  def removespell(name)
    @spellpoints += @spells[name][1]
    @spells.delete(name)
  end
  
  def checktotem(totem,group)
    if totem 
      if CONSTANT[:totems][group][totem][:req]
        CONSTANT[:totems][group][totem][:req].each do |x|
          if CONSTANT[:attributes].include? x[0]
            @attributes[x[0]][:ACT] < x[1] ? (return false) : true
          else
            @derived[x[0]][:CBM] < x[1] ? (return false) : true
          end
        end
      else
        true
      end
    end
  end

  def settotem(totem,group,boni)
    if checktotem(totem,group)
      @totem = [totem,group,boni]
    else
      @totem = nil
    end
  end

  def setweight(weight)
    @weight = weight
  end

  def findattr(skill)
    CONSTANT[:activeskills].find {|x| x[1].include? skill}[0]
  end

  def checkskills(attr,value,oldvalue,check)
    totalpoints = 0, points = {}
    @activeskills[attr].each do |x|
      if value > oldvalue
        if x[1][:Value] >= value
          points[x[0]] = (value - oldvalue) * -1
        else
          if x[1][:Value] > oldvalue
            points[x[0]] = (value - x[1][:Value]) * -1
          else
            points[x[0]] = 0
          end
        end
      else
        if x[1][:Value] > value
          if x[1][:Value] > oldvalue
            points[x[0]] = (oldvalue - value)
          else
            points[x[0]] = (x[1][:Value] - value)
          end
        else
          points[x[0]] = 0
        end
      end
    end
    totalpoints = points.values.inject(0) {|totalpoints,y| totalpoints+y}
    if checkpoints(totalpoints) || check == 1
      @activeskills[attr].each {|x| x[1][:Points]+=points[x[0]]}
      modpoints(totalpoints)
      true
    else
      false
    end
  end

  def skilllvl(skill,value)
    attrib = findattr(skill)
    current = @activeskills[attrib][skill][:Value]
    if value < current
      if current > @attributes[attrib][:ACT]
        if value > @attributes[attrib][:ACT]
          points = ((current - value) * -2)
        else
          points = (((current - @attributes[attrib][:ACT]) *-2) +
                    ((@attributes[attrib][:ACT] - value) *-1))
        end
      else
        points = ((current - value)*-1)
      end
    else
      if current > @attributes[attrib][:ACT]
        points = ((value - current)*2)
      else
        if value > @attributes[attrib][:ACT]
        points = (((value - @attributes[attrib][:ACT]) *2) +
                  ((@attributes[attrib][:ACT] - current) *1))
        else
          points = (value - current)
        end
      end
    end
    if checkpoints(points)
      modpoints(points)
      @activeskills[attrib][skill][:Value] = value
      @activeskills[attrib][skill][:Points] += points
    end
    @activeskills[attrib][skill]
  end

  def delskill(skill)
    attrib = findattr(skill)
    modpoints(@activeskills[attrib][skill][:Points] * -1)
    @activeskills[attrib].delete(skill)
  end

  def addskill(attr,skill,special)
    if checkpoints(1)
      modpoints(1)
      @activeskills[attr][skill]=
        {Points: 1, Specialization: special ? special : nil, Value: 1}
      @activeskills[attr][skill][:Value] = 1
      @activeskills[attr][skill][:Points] = 1
      [attr,skill,special]
    else 0
    end
  end
    

  def vcr
    @cyberware[:Bodyware].find {|x| x[0] == :VCR}
  end

  def deck
  end

  def cinit
    all = @cyberware[:Bodyware].find_all {|x| x[1][:Stats][:Initiative]}
    sum = all.inject(0) {|sum,x| sum + x[1][:Stats][:Initiative]}
  end

  def binit
    all = @bioware.find_all {|x| x[1][:Stats][:Initiative]}
    sum = all.inject(0) {|sum,x| sum + x[1][:Stats][:Initiative]}
  end

  def reaccbm
    reac = 0
    [:Intelligence,:Quickness].each do |x|
      [:BA,:CM,:BM,:MM]. each do |y|
        reac += @attributes[x][y]
      end
    end
    (reac / 2).floor
  end

  def updatereaction
    @derived[:Reaction][:Base] = ((@attributes[:Quickness][:BA] + 
                     @attributes[:Intelligence][:BA]) / 2).floor
    @derived[:Reaction][:CBM] = reaccbm
    @derived[:Reaction][:Rigg] = vcr ? vcr[1][:Stats][:Reaction] +
      @derived[:Reaction][:Base] : @derived[:Reaction][:Base]
    @derived[:Reaction][:Deck] = @derived[:Reaction][:Base]
    @derived[:Reaction][:Astral] = getmagic ? @attributes[:Intelligence][:ACT] +
      20 : @attributes[:Intelligence][:ACT]
    if @totem && CONSTANT[:totems][@totem[1]][@totem[0]][:req]
      @app.settotem(@totem[0],@totem[1])
    end
    @derived[:Reaction]
  end
  
  def updateinitiative 
    @derived[:Initiative][:Base] = 1
    @derived[:Initiative][:CBM] = 1 + cinit + binit
    @derived[:Initiative][:Rigg] = vcr ? vcr[1][:Stats][:Initiative] +1 : 1
    @derived[:Initiative][:Deck] = deck ? deck : 1
    @derived[:Initiative][:Astral] = getmagic ? 2 : 1
    @derived[:Initiative]
  end

  def updatepool(pool)
    case pool
    when :'Magic Pool' then updatemagicpool
    when :'Astral Pool' then updateastralpool
    when :'Combat Pool' then updatecombatpool
    when :'Hacking Pool' then updatehackingpool
    when :'Control Pool' then updatecontrolpool
    end
  end

  def updatemagicpool
    if getmagic && @magetype =~ /Full|Elem|Shamanist|Sorc/
      @derived[:Pools][:'Magic Pool'] = ((@attributes[:Intelligence][:ACT] + 
        @attributes[:Willpower][:ACT] + @special[:Magic]) / 2).floor
    else
      @derived[:Pools][:'Magic Pool'] = 0
    end
  end
  
  def updateastralpool
    if @magetype =~ /Full/
      @derived[:Pools][:'Astral Pool'] = ((@attributes[:Intelligence][:ACT] +
        @attributes[:Charisma][:ACT] + @attributes[:Willpower][:ACT]) / 2).floor
    else
      @derived[:Pools][:'Astral Pool'] = 0
    end
  end

  def updatecombatpool
    @derived[:Pools][:'Combat Pool'] = ((@attributes[:Intelligence][:ACT] +
      @attributes[:Quickness][:ACT] + @attributes[:Willpower][:ACT]) / 2).floor
  end

  def updatehackingpool
    @derived[:Pools][:'Hacking Pool'] = 0
  end

  def updatecontrolpool
    @derived[:Pools][:'Control Pool'] = 0
  end

  def checkage
    @age = @age > CONSTANT[:metatypes][@metatype][:Age] ? 
      CONSTANT[:metatypes][@metatype][:Age] : @age
  end

  def checkheight
    @height = CONSTANT[:metatypes][@metatype][:Height]
  end

  def checkweight
    @weight = CONSTANT[:metatypes][@metatype][:Weight]
  end

  def setmetatype(metatype)
    meta, points = metatype.active_text.split(':')
    pointsdiff = points.to_i - CONSTANT[:metatypes][@metatype][:Points]
    if checkpoints(pointsdiff)
      modpoints(pointsdiff)
      @metatype = meta.to_sym
      @app.metachecks(@metatype)
    end
    CONSTANT[:metatypes].find_index { |x| x[0] == @metatype }
  end
  
  def clearspells
    @spells = {}
  end

  def setmagetype(magetype)
    mage, points = magetype.active_text.split(':')
    pointsdiff = points.to_i - CONSTANT[:magetypes][@magetype][:Points]
    if checkpoints(pointsdiff)
      modpoints(pointsdiff)
      @magetype = mage.to_sym
    end
    clearspells
    CONSTANT[:magetypes].find_index { |x| x[0] == @magetype }
  end

  def setmagic
    @special[:Magic] = @magetype == :None ? 0 : @special[:Essence]
  end
  
  def getmagetype
    @magetype
  end

  def getmetatype
    @metatype
  end

  def getmagic
    @special[:Magic] > 0
  end

  def setnuyen(nuyen)
    money, points = nuyen.active_text.split(':').map(&:to_i)
    pointsdiff = points - CONSTANT[:nuyen].rassoc(@nuyen)[0]
    if checkpoints(pointsdiff)
      modpoints(pointsdiff)
      diff = @nuyen - @nuyenrem
      @nuyen = money
      @nuyenrem = @nuyen - diff
      nuyen.active
    else
      CONSTANT[:nuyen].find_index { |x,y| y == @nuyen}
    end
  end

  def getnuyen
    CONSTANT[:nuyen].find_index {|x,y| y == @nuyen}
  end

  def getage
    @age
  end

  def getheight
    @height
  end

  def getweight
    @weight
  end

  def getnuyenrem
    @nuyenrem
  end

  def checkpoints(points)
    @pointsrem >= points
  end

  def modpoints(points)
    @pointsrem -= points
  end

  def getpointsrem
    @pointsrem
  end

  def setspellpoints
    @spellpoints = CONSTANT[:magetypes][@magetype][:Spellpoints]
  end

  def getspellpoints
    @spellpoints
  end

  def updateattr(attr)
    @app.checkskills(attr, @attributes[attr][:BA] + @attributes[attr][:BM] +
                     @attributes[attr][:CM] + @attributes[attr][:MM],
                     @attributes[attr][:ACT],1)
    @attributes[attr][:BA] = @attributes[attr][:Points] / 2 +
                             @attributes[attr][:RM]
    @attributes[attr][:ACT] = @attributes[attr][:BA] + @attributes[attr][:BM] +
                              @attributes[attr][:CM] + @attributes[attr][:MM]
    if @totem && CONSTANT[:totems][@totem[1]][@totem[0]][:req]
      @app.settotem(@totem[0],@totem[1])
    end
    @attributes[attr]
  end

  def setattribute(attr, value)
    if (value / 2 + @attributes[attr][:RM] > 0) && value.to_i.even?
      if checkpoints(value - @attributes[attr][:Points])
        if @app.checkskills(attr,value/2,@attributes[attr][:ACT])
          modpoints(value - @attributes[attr][:Points])
          @attributes[attr][:Points] = value
        end
      end
    end
    @attributes[attr][:Points]
  end

  def setmetamods
    CONSTANT[:metatypes][@metatype][:Racialmods].each_pair do |x, y|
      @attributes[x][:BA] = @attributes[x][:Points] / 2 + y
      if (y > @attributes[x][:RM]) && (@attributes[x][:RM] < 0)
        diff = y - @attributes[x][:RM]
        @attributes[x][:Points] -= diff * 2
        @attributes[x][:BA] -= diff
        modpoints(diff * -2)
      end
      if @attributes[x][:BA] <= 0
        diff = 1 + @attributes[x][:BA].abs
        @attributes[x][:BA] += diff
        @attributes[x][:Points] += diff * 2
        modpoints(diff * 2)
      end
      @attributes[x][:RM] = y
      @app.updateattr(x)
    end
  end

  def initialize(app)
    @magetype = :None
    @metatype = :Human
    @app = app
    @points = 120
    @pointsrem = 108
    @age = 15
    @height = 170
    @weight = 70
    @nuyen = 5000
    @nuyenrem = 5000
    @activeskills = {}
    @spells = {}
    @totem = nil 
    @cyberware = {:Bodyware => {}, :Senseware => {}, :Cyberlimbs => {},
                  :Headware => {}}
    @bioware = {}
    @derived = {:Pools => {}, :Reaction => {}, :Initiative => {}}
    @special = { :Essence => 6, :'Body Index' => 0, :Magic => 0 }
    @attributes = {}
    CONSTANT[:attributes].each do |x|
      @activeskills[x]={}
      @attributes[x] = {}
      CONSTANT[:attrinfo].each do |y|
        @attributes[x][y] = case y
                            when :BA then 1
                            when :Points then 2
                            when :ACT then 1
                            else 0
                            end
      end
    end
    CONSTANT[:derived][:Pools].each do |x|
      @derived[:Pools][x] = (x =~ /Astral|Magic/) ? 0 : 1
    end
  end
end

class Mainblock < Gtk::Frame
  def checkage(age,meta)
    @elements[:Age][1].set_range(15,meta[:Age])
    setage(age)
  end

  def checkheight(height,meta)
    @elements[:Height][1].set_range(meta[:Height]*0.75,meta[:Height]*1.25)
    setheight(height)
  end

  def checkweight(weight,meta)
    @elements[:Weight][1].set_range(meta[:Weight]*0.75,meta[:Weight]*2)
    setweight(weight)
  end

  def setname(name)
    @elements[:Name][1].text = name
  end

  def setstreetname(sname)
    @elements[:Streetname][1].text = sname
  end

  def setage(age)
    @elements[:Age][1].value = age
  end

  def setgender(gender)
    @elements[:Gender][1].active = gender
  end

  def setmetatype(metatype)
    @elements[:Metatype][1].active = metatype
  end

  def setmagetype(magetype)
    @elements[:Magetype][1].active = magetype
  end

  def setnuyen(nuyen)
    @elements[:Nuyen][1].active = nuyen
  end

  def setheight(height)
    @elements[:Height][1].value = height
  end

  def setweight(weight)
    @elements[:Weight][1].value = weight
  end

  def setnuyenrem(nuyen)
    @elements[:Nuyenrem][1].text = nuyen.to_s
  end

  def setpointsrem(points)
    @elements[:Pointsrem][1].text = points.to_s
  end

  def initialize(app)
    super()
    @app = app
    @table = Gtk::Table.new(7, 4)
    @elements = {
      Name: [Gtk::Label.new('Name'), Gtk::Entry.new],
      Streetname: [Gtk::Label.new('Streetname'), Gtk::Entry.new],
      Age: [Gtk::Label.new('Age'), Gtk::SpinButton.new(15.0, 70.0, 1.0)],
      Gender: [Gtk::Label.new('Gender'), Gtk::ComboBox.new],
      Metatype: [Gtk::Label.new('Metatype'), Gtk::ComboBox.new],
      Magetype: [Gtk::Label.new('Magetype'), Gtk::ComboBox.new],
      Nuyen: [Gtk::Label.new('Nuyen'), Gtk::ComboBox.new],
      Nuyenrem: [Gtk::Label.new('¥ left'), Gtk::Label.new('¥')],
      Height: [Gtk::Label.new('Height'), Gtk::SpinButton.new(128.0, 213.0, 1.0)],
      Weight: [Gtk::Label.new('Weight'), Gtk::SpinButton.new(53.0, 140.0, 1.0)],
      Points: [Gtk::Label.new('Points'), Gtk::Label.new('120')],
      Pointsrem: [Gtk::Label.new('P left'), Gtk::Label.new('108')]
    }
    @elements[:Height][1].width_chars = 3
    @elements[:Weight][1].width_chars = 3
    @elements[:Age][1].width_chars = 2
    @elements[:Name][1].width_chars = 20
    @elements[:Streetname][1].width_chars = 20
    CONSTANT[:gender].each do |x|
      @elements[:Gender][1].append_text(x.to_s.capitalize)
    end
    CONSTANT[:metatypes].each_pair do |x, y|
      @elements[:Metatype][1].append_text(x.to_s + ':' + y[:Points].to_s)
    end
    CONSTANT[:magetypes].each_pair do |x, y|
      @elements[:Magetype][1].append_text(x.to_s + ':' + y[:Points].to_s)
    end
    CONSTANT[:nuyen].each_pair do |x, y|
      @elements[:Nuyen][1].append_text(y.to_s + ':' + x.to_s)
    end

    @elements[:Metatype][1].active = 0
    @elements[:Magetype][1].active = 0
    @elements[:Age][1].value = 20
    @elements[:Height][1].value = 170
    @elements[:Weight][1].value = 70
    @elements[:Nuyen][1].active = 1
    @elements[:Nuyenrem][1].text = "5000"

    @elements[:Name][1].signal_connect('activate') { |x| @app.setname(x) }
    @elements[:Streetname][1].signal_connect('activate') { |x| @app.setstreetname(x) }
    @elements[:Age][1].signal_connect('value_changed') { |x| @app.setage(x) }
    @elements[:Gender][1].signal_connect('changed') { |x| @app.setgender(x) }
    @elements[:Metatype][1].signal_connect('changed') { |x| @app.setmetatype(x) }
    @elements[:Magetype][1].signal_connect('changed') { |x| @app.setmagetype(x) }
    @elements[:Nuyen][1].signal_connect('changed') { |x| @app.setnuyen(x) }
    @elements[:Height][1].signal_connect('value_changed') { |x| @app.setheight(x) }
    @elements[:Weight][1].signal_connect('value_changed') { |x| @app.setweight(x) }
    i = 2
    @elements.each_slice(2) do |x|
      @table.attach x[0][1][0], i, i + 1, 0, 1, *ATCH
      @table.attach x[0][1][1], i, i + 1, 1, 2, *ATCH
      @table.attach x[1][1][0], i, i + 1, 2, 3, *ATCH
      @table.attach x[1][1][1], i, i + 1, 3, 4, *ATCH
      i += 1
    end
    @elements[:Load] = Gtk::Button.new(Gtk::Stock::OPEN)
    @elements[:Save] = Gtk::Button.new(Gtk::Stock::SAVE)
    @elements[:Load].signal_connect('clicked') { @app.load }
    @elements[:Save].signal_connect('clicked') { @app.save }

    @table.attach Gtk::Image.new('srlogo.png'), 0, 2, 0, 3, *ATCH
    @table.attach @elements[:Load], 0, 1, 3, 4, *ATCH
    @table.attach @elements[:Save], 1, 2, 3, 4, *ATCH
    
    @table.n_rows = 4
    @table.n_columns = 8
    add(@table)
    #	binding.pry
  end
end

class Attributeblock < Gtk::Frame
  def updateattr(attr, datablock)
    @attributes[attr][:RM].text = datablock[:RM].to_i.to_s
    @attributes[attr][:BA].text = datablock[:BA].to_i.to_s
    @attributes[attr][:CBM].text = (datablock[:CM] + datablock[:BM]).to_i.to_s
    @attributes[attr][:MM].text = datablock[:MM].to_i.to_s
    @attributes[attr][:ACT].text = datablock[:ACT].to_i.to_s
    @attributes[attr][:Points].value = datablock[:Points]
  end

  def setspellpoints(points)
    @special[:Spellpoints][1].text = points.to_s
  end

  def setmagic(magic)
    @special[:Magic][1].text = magic.to_s
  end

  def setattribute(attr, value)
    @attributes[attr][:Points].value = value
  end

  def updatereaction(reaction)
    reaction.each_pair do |x,y|
      @derived[:Reaction][x].text = y.to_i.to_s
    end
  end
  
  def updateinitiative(initiative)
    initiative.each_pair do |x,y|
      @derived[:Initiative][x].text = y.to_i.to_s + "D6"
    end
  end

  def updatepool(pool,value)
    @derived[:Pools][pool].text = value.to_s
  end

  def fetchtp(attr,ratings = nil)
    ratings ? File.open("attributes.txt").read[/Human.+Unmodified Human/m] : 
      File.open("attributes.txt").find_all {|x| x.include? attr}[1]
  end

  def enabletotem
    @totem.each {|x| x.sensitive = true}
    if not @totemsenabled 
      CONSTANT[:totems].each_key {|x| @totem[1].append_text(x.to_s)}
      @totemsenabled = 1
    end
    @totem[1].active = -1
  end

  def disabletotem
    @totem.each do |x|
      x.active = -1 if x.class == Gtk::ComboBox
      x.sensitive = false
    end
    @tooltips.set_tip(@totem[3],'',nil)
    5.times {|x| @totem[1].remove_text(0)}
    @totemsenabled = nil
  end

  def cleartotems
    @totemcount.times do |y|
      @totem[3].remove_text(0)
    end
    @totemcount = 0
  end

  def availabletotems(totems)
    @totemcount = totems.count
    totems.each do |x|
      @totem[3].append_text(x.to_s)
    end
  end

  def nototem
    @totem[3].active = -1
  end

  def settotemboni(boni)
    if boni
      @totem[5].text = boni[2][:spells] ? 
        boni[2][:spells].collect {|x| x[0].to_s + ":" + x[1].to_s}.join(", ") : ""
      @totem[7].text = boni[2][:spirits] ? 
        boni[2][:spirits].collect {|x| x[0].to_s + ":" + x[1].to_s}.join(", ") : ""
    else
      @totem[5].text = ''
      @totem[7].text = ''
    end
  end

  def initialize(app)
    @tooltips=Gtk::Tooltips.new
    @app = app
    @totemsenabled = nil
    super()
    @table = Gtk::Table.new(10, 7, homogenous = true)
    @attributes = {}
    @derived = {}
    @special = {:Essence => [],:Magic => [], :'Body Index' => [], :Spellpoints => []}
    @header = {}
    @table.attach @header[:Attributes] = Gtk::Label.new('Attributes'), 0, 3, 0, 1, *ATCH
    @table.attach @header[:Points] = Gtk::Label.new('Points'), 3, 5, 0, 1, *ATCH
    @table.attach @header[:RM] = Gtk::Label.new('RM'), 5, 6, 0, 1, *ATCH
    @table.attach @header[:BA] = Gtk::Label.new('BA'), 6, 7, 0, 1, *ATCH
    @table.attach @header[:CBM] = Gtk::Label.new('CB'), 7, 8, 0, 1, *ATCH
    @table.attach @header[:MM] = Gtk::Label.new('MM'), 8, 9, 0, 1, *ATCH
    @table.attach @header[:ACT] = Gtk::Label.new('AC'), 9, 10, 0, 1, *ATCH

    @tooltips.set_tip(@header[:Attributes],fetchtp(nil,1),nil)
    @tooltips.set_tip(@header[:Points],"Build Points, 2 to raise Attribute by 1",nil)
    @tooltips.set_tip(@header[:RM],"Racial Modifier to base Attribute",nil)
    @tooltips.set_tip(@header[:BA],"Base Attribute after applying racial Modifiers",nil)
    @tooltips.set_tip(@header[:CBM],"Cyberware/Bioware Modifiers to base Attribute",nil)
    @tooltips.set_tip(@header[:MM],"Magic/Power Modifiers to base Attribute",nil)
    @tooltips.set_tip(@header[:ACT],"Actual effective Attribute after all Modifiers",nil)

    CONSTANT[:attributes].each_with_index do |x, y|
      @attributes[x] = {}
      @table.attach @attributes[x][:Attributes] = Gtk::Label.new(x.to_s), 0, 3, y * 2 + 1, y * 2 + 3, *ATCH
      @table.attach @attributes[x][:Points] = Gtk::HScale.new(2, 12, 2), 3, 5, y * 2 + 1, y * 2 + 3, *ATCH
      @table.attach @attributes[x][:RM] = Gtk::Label.new('0'), 5, 6, y * 2 + 1, y * 2 + 3, *ATCH
      @table.attach @attributes[x][:BA] = Gtk::Label.new('1'), 6, 7, y * 2 + 1, y * 2 + 3, *ATCH
      @table.attach @attributes[x][:CBM] = Gtk::Label.new('0'), 7, 8, y * 2 + 1, y * 2 + 3, *ATCH
      @table.attach @attributes[x][:MM] = Gtk::Label.new('0'), 8, 9, y * 2 + 1, y * 2 + 3, *ATCH
      @table.attach @attributes[x][:ACT] = Gtk::Label.new('1'), 9, 10, y * 2 + 1, y * 2 + 3, *ATCH
      @attributes[x][:Points].set_update_policy(Gtk::UPDATE_CONTINUOUS)
      @attributes[x][:Points].signal_connect('value_changed') do |z|
        @app.setattribute(x, z)
      end
      @tooltips.set_tip(@attributes[x][:Attributes],fetchtp(x.to_s),nil)
    end

    @table.attach Gtk::Label.new('Reaction/Initiative'), 0, 10, 14, 15, *ATCH
    @derived[:Reaction] = {}
    @derived[:Initiative] = {}
    CONSTANT[:derived][:Reaction].each_with_index do |x, y|
      @table.attach Gtk::Label.new(x.to_s), y * 2, y * 2 + 2, 15, 16, *ATCH
      @table.attach @derived[:Reaction][x] = Gtk::Label.new('0'), y * 2, y * 2 + 1, 16, 17, *ATCH
      @table.attach @derived[:Initiative][x] = Gtk::Label.new('0D6'), y * 2 + 1, y * 2 + 2, 16, 17, *ATCH
    end

    @derived[:Pools] = {}
    CONSTANT[:derived][:Pools].each_with_index do |x, y|
      @table.attach Gtk::Label.new(x.to_s), 0, 4, 18 + y, 19 + y, *ATCH
      @table.attach @derived[:Pools][x] = Gtk::Label.new('0'), 4, 5, 18 + y, 19 + y, *ATCH
    end

    @table.attach @special[:Essence][0] = Gtk::Label.new('Essence'), 6, 9, 18, 19, *ATCH
    @table.attach @special[:Essence][1] = Gtk::Label.new('6'), 9, 10, 18, 19, *ATCH
    @table.attach @special[:'Body Index'][0] = Gtk::Label.new('Body Index'), 6, 9, 19, 20, *ATCH
    @table.attach @special[:'Body Index'][1] = Gtk::Label.new('0'), 9, 10, 19, 20, *ATCH
    @table.attach @special[:Magic][0] = Gtk::Label.new('Magic'), 6, 9, 20, 21, *ATCH
    @table.attach @special[:Magic][1] = Gtk::Label.new('0'), 9, 10, 20, 21, *ATCH
    @table.attach @special[:Spellpoints][0] = Gtk::Label.new('Spellpoints'), 6, 9, 21, 22, *ATCH
    @table.attach @special[:Spellpoints][1] = Gtk::Label.new('0'), 9, 10, 21, 22, *ATCH
    
    @special.each do |x|
      @tooltips.set_tip(x[1][0],fetchtp(x[0].to_s),nil)
    end

    @table.attach Gtk::VSeparator.new, 5, 6, 18, 23, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 13, 14, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 17, 18, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 23, 24, *ATCH
    
    @totem = []
    @totemcount = 0
    @table.attach @totem[0] = Gtk::Label.new('Type'),0,3,24,26,*ATCH
    @table.attach @totem[1] = Gtk::ComboBox.new,3,10,24,26,*ATCH
    @table.attach @totem[2] = Gtk::Label.new('Totem'),0,3,26,28,*ATCH
    @table.attach @totem[3] = Gtk::ComboBox.new,3,10,26,28,*ATCH
    @table.attach @totem[4] = Gtk::Label.new('Spells'),0,10,28,29,*ATCH
    @table.attach @totem[5] = Gtk::Label.new(''),0,10,29,31,*ATCH
    @table.attach @totem[6] = Gtk::Label.new('Spirits'),0,10,31,32,*ATCH
    @table.attach @totem[7] = Gtk::Label.new(''),0,10,32,34,*ATCH
    @totem[5].wrap = true
    @totem[5].justify = Gtk::JUSTIFY_FILL 
    @totem[5].width_chars = 40
    @totem[7].wrap = true
    @totem[7].justify = Gtk::JUSTIFY_FILL
    @totem[7].width_chars = 40

    @totem.each {|x| x.sensitive=false}

    @totem[1].signal_connect('changed') do |x|
      cleartotems
      if x.active_text
        @app.availabletotems(x.active_text.to_sym)
      end
    end

    @totem[3].signal_connect('changed') do |x|
      if x.active_text
        temp = CONSTANT[:totems][@totem[1].active_text.to_sym][x.active_text.to_sym]
        @tooltips.set_tip(@totem[3],(temp[:desc] ? temp[:desc]+"\n" : '')+
          (temp[:properties] ? temp[:properties] : ''),nil)
        @app.settotem(x.active_text.to_sym,@totem[1].active_text.to_sym)
      else
        @tooltips.set_tip(@totem[3],'',nil)
        @app.settotem(nil,nil)
      end
#      x.active = -1 unless @app.gettotem
      settotemboni(@app.gettotem)
    end
    add(@table)
  end
end

class Skillblock < Gtk::ScrolledWindow

  def skilllvl(skill,data)
    @skillentries[skill][2].value = data[:Value]
    @skillentries[skill][3].text = 
      data[:Specialization] ? 
      "#{(data[:Value]-1).to_i}|#{(data[:Value]+1).to_i}" : "#{(data[:Value]).to_i}"
  end
  
  def updatecombo(change,count)
    count.times do |x|
      @header[change][1].remove_text(0)
    end
    @header[change][1].active=-1
  end

  def getattr
    @header[:Attribute][1].active_text.to_sym
  end

  def getskill
    @header[:Skill][1].active_text.to_sym
  end

  def getspecial
    if @header[:Specialization][1].active_text
      @header[:Specialization][1].active_text.to_sym
    end
  end

  def addskill(x)
    if x != 0
      row=@skillentries.count
      @skillentries[x[1]] = 
        [Gtk::Label.new(x[1].to_s),Gtk::Label.new(x[2].to_s),
         Gtk::HScale.new(1,6,1),Gtk::Label.new(x[2] ? "0|2" : "1"),
         Gtk::Button.new(Gtk::Stock::NO)]
      @skillentries[x[1]][4].signal_connect('clicked') { |y| @app.delskill(x) }
      @skillentries[x[1]][2].signal_connect('value_changed') { |y| 
        @app.skilllvl(x[1],y)}
      @table2.attach @skillentries[x[1]][0],0,4,row,row+1,*ATCH
      @table2.attach @skillentries[x[1]][1],4,8,row,row+1,*ATCH
      @table2.attach @skillentries[x[1]][2],8,10,row,row+1,*ATCH
      @table2.attach @skillentries[x[1]][3],10,11,row,row+1,*ATCH
      @table2.attach @skillentries[x[1]][4],11,12,row,row+1,*ATCH
      @table2.show_all
    end
  end

  def delskill(skill)
    row = @table2.child_get_property(
      @table2.children.find {|x| x.text == skill.to_s if x.class == Gtk::Label},
      'top-attach')
    @skillentries[skill].each {|x| @table2.remove(x)}
    @skillentries.delete(skill)
    @table2.children.each do |x|
      top = @table2.child_get_property(x,'top-attach')
      if top > row
        @table2.child_set_property(x,'top-attach',top-1)
        @table2.child_set_property(x,'bottom-attach',top)
      end
    end
    @table2.n_rows = @table2.n_rows - 1
  end

  def initialize(app)
    @app = app
    super()
    self.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    @tooltips = Gtk::Tooltips.new
    @maintable = Gtk::Table.new(1,3)
    @table = Gtk::Table.new(12, 3, homogenous = true)
    @table2 = Gtk::Table.new(12 , 1, homogenous = true)
    @skillentries = {}
    @skills = {}
    @skillcount=0
    @speccount=0
    @header = {}
    @header2 = {}
    @header[:Attribute] = [Gtk::Label.new('Attribute'), Gtk::ComboBox.new]
    @header[:Skill] = [Gtk::Label.new('Skill'), Gtk::ComboBox.new]
    @header[:Specialization] = [Gtk::Label.new('Specialization'), Gtk::ComboBox.new]
    @header[:ADD] = Gtk::Button.new('Add')
    @header[:ADD].sensitive = false

#    @model = Gtk::TreeStore.new(String)
#    @view = Gtk::TreeView.new(@model)
#    CONSTANT[:activeskills].keys.each do |x|
#      parent = @model.append(nil)
#      parent[0] = x
#      CONSTANT[:activeskills][x].keys.each do |y|
#        child = @model.append(parent)
#        child[0]=y
#      end
#    end
#    1.times do |x|
#      renderer = Gtk::CellRendererText.new
#      col = Gtk::TreeViewColumn.new("Name",renderer,:text => 0)
#      @view.append_column(col)
#    end
#    @window = Gtk::Window.new
#    @window.add(@view)
#    @window.show_all

    @header[:ADD].signal_connect('clicked') do |x|
      @app.addskill(getattr,getskill,getspecial) unless @skillentries.include? getskill
    end

    @header[:Attribute][1].signal_connect('changed') do |x|
      updatecombo(:Skill,@skillcount)
      @skillcount = CONSTANT[:activeskills][x.active_text.to_sym].count
      @header[:ADD].sensitive = false
      CONSTANT[:activeskills][x.active_text.to_sym].each_key do |y|
        @header[:Skill][1].append_text(y.to_s)
      end
    end

    @header[:Skill][1].signal_connect('changed') do |x|
      updatecombo(:Specialization,@speccount)
      if x.active_text
        @speccount = CONSTANT[:activeskills][getattr][x.active_text.to_sym][:Specialization].count
        @header[:ADD].sensitive = true
        CONSTANT[:activeskills][getattr][x.active_text.to_sym][:Specialization].each do |y|
          @header[:Specialization][1].append_text(y.to_s)
        end
        @tooltips.set_tip(@header[:Skill][1],CONSTANT[:activeskills][getattr][x.active_text.to_sym][:Desc],nil)
      else
        @tooltips.set_tip(@header[:Skill][1],nil,nil)
      end
    end

    CONSTANT[:attributes].each do |x|
      @header[:Attribute][1].append_text(x.to_s)
    end

    @table.attach @header[:Attribute][0], 0, 3, 0, 1, *ATCH
    @table.attach @header[:Attribute][1], 0, 3, 1, 2, *ATCH
    @table.attach @header[:Skill][0], 3, 8, 0, 1, *ATCH
    @table.attach @header[:Skill][1], 3, 8, 1, 2, *ATCH
    @table.attach @header[:Specialization][0], 8, 12, 0, 1, *ATCH
    @table.attach @header[:Specialization][1], 8, 13, 1, 2, *ATCH
    @table.attach @header[:ADD], 12, 13, 0, 1, *ATCH
    @table.attach @header2[:Skill] = Gtk::Label.new('Skill'), 0, 4, 2, 3, *ATCH
    @table.attach @header2[:Specialization] = Gtk::Label.new('Specialization'), 4, 9, 2, 3, *ATCH
    @table.attach @header2[:Points] = Gtk::Label.new('Points'), 9, 11, 2, 3, *ATCH
    @table.attach @header2[:Value] = Gtk::Label.new('Value'), 11, 12, 2, 3, *ATCH
    @table.n_rows = 3
    @table.n_columns = 13
    @table2.n_rows = 1
    @maintable.attach @table,0,1,0,1,*ATCH
    @maintable.attach @table2,0,1,1,2,*ATCH
    add_with_viewport(@maintable)
  end
end

class Spellblock < Gtk::Frame
  def enablespells(spells)
  newspell
  @view.collapse_all
  @allowed = spells
  end

  def spelllvl(name,value)
    @spells[name][2].value = value
  end
  
  def clear(which=nil)
    newspell
    @allowed = nil
    @view.collapse_all
    @spells = {}
  end

  def addspells(parent,rows)
    rows.values.each do |a|
      child = @model.append(parent)
      a.each_pair do |b,c|
        child[@order[b]] = c.to_s if @order[b]
      end
    end
  end

  def removespell(name)
    row = @table.child_get_property(
      @table.children.find {|x| x.text == name if x.class == Gtk::Label},
      'top-attach')
    @spells[name].each {|x| @table.remove(x)}
    @spells.delete(name)
    @table.children.each do |x|
      top = @table.child_get_property(x,'top-attach')
      if top > row
        @table.child_set_property(x,'top-attach',top-1)
        @table.child_set_property(x,'bottom-attach',top)
      end
    end
  end
  
  def newspell
    @spells.each_pair do |x,y|
      y.each do |z|
        @table.remove(z)
        z.destroy
      end
    end
    @table.n_columns = 11
    @table.n_rows = 1
  end

  def appendspell(name,category,subcategory)
    count = @spells.count
    @spells[name] = [ 
      Gtk::Label.new(name),Gtk::Label.new(subcategory ? category+"/"+subcategory : category),
      Gtk::HScale.new(1,6,1),Gtk::Button.new(Gtk::Stock::NO)]
    @spells[name][2].value_pos = Gtk::POS_RIGHT
    @spells[name][2].signal_connect('value_changed') {|x| @app.spelllvl(name,x.value)}
    @spells[name][3].signal_connect('clicked') {|x| @app.removespell(name)}
    @table.attach @spells[name][0],0,4,1+count,2+count,*ATCH
    @table.attach @spells[name][1],4,8,1+count,2+count,*ATCH
    @table.attach @spells[name][2],8,10,1+count,2+count,*ATCH
    @table.attach @spells[name][3],10,11,1+count,2+count,*ATCH
    @table.show_all
  end

    
  def initialize(app)
    @app = app
    @allowed = nil
    super()
    @win = Gtk::ScrolledWindow.new
    @win2 = Gtk::ScrolledWindow.new
    @vbox = Gtk::VBox.new(true,nil)
    @table = Gtk::Table.new(11,1,true)
    @spells = {}
    @header2 = {}
    @model = Gtk::TreeStore.new(String, String, String, String, String, String, String, String, String)
    @view = Gtk::TreeView.new(@model)
    @order = {}
    %w(Name Dur Range Area DTN DLVL Damage DamType Element).each_with_index do |a,b|
      @order[a.to_sym]=b
    end
    [:Combat,:Detection,:Health].each do |x|
      parent = @model.append(nil)
      parent[0] = x
      addspells(parent,CONSTANT[:spelltypes][x])
    end
    [:Illusion,:Manipulation].each do |x|
      parent = @model.append(nil)
      parent[0] = x
      CONSTANT[:subspelltypes][x].each do |y|
        parent2 = @model.append(parent)
        parent2[0]=y
        addspells(parent2,CONSTANT[:spelltypes][x][y])
      end
    end

    @view.signal_connect('row-expanded') do |a,b,c|
      case b[0].to_sym
      when :Indirect,:Direct
        a.collapse_row(c) unless (@allowed.include?(:Illusion) || @allowed.include?(b[0].to_sym))
      when :Telekinetic,:Control,:Transformation
        a.collapse_row(c) unless (@allowed.include?(:Manipulation) || @allowed.include?(b[0].to_sym))
      when :Elemental
        a.collapse_row(c) unless (@allowed.include?(:Manipulation) || 
                                  @allowed.include?(b[0].to_sym) || 
                                  !(@allowed & [:Fire,:Lightning,:Water,:Smoke]).empty?)
      when :Manipulation
        a.collapse_row(c) unless (!(@allowed & CONSTANT[:subspelltypes][b[0].to_sym]).empty? || 
                                  @allowed.include?(b[0].to_sym) || 
                                  !(@allowed & [:Fire,:Lightning,:Water,:Smoke]).empty?)
      when :Illusion
        a.collapse_row(c) unless (!(@allowed & CONSTANT[:subspelltypes][b[0].to_sym]).empty? || 
                                  @allowed.include?(b[0].to_sym))
      when :Health,:Detection,:Combat
        a.collapse_row(c) unless (@allowed.include?(b[0].to_sym))
      end
    end

    @view.signal_connect('row-activated') do |a,b,c|
      subcategory = nil
      name = @model.get_iter(b)[0]
      unless (CONSTANT[:spelltypes].keys + CONSTANT[:subspelltypes][:Manipulation] +
          CONSTANT[:subspelltypes][:Illusion]).include? name.to_sym
        if b.depth == 3
          b.up!
          subcategory = @model.get_iter(b)[0]
        end
        b.up!
        category = @model.get_iter(b)[0]
        pp a.selection.selected[0]
        @app.appendspell(name,category,subcategory) unless @spells[name]
      else
        a.row_expanded?(b) ? a.collapse_row(b) : a.expand_row(b,false)
      end
    end 

    (0..8).each do |x|
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
      col.set_sizing  Gtk::TreeViewColumn::GROW_ONLY
      @view.append_column(col)
    end
    @view.enable_grid_lines = Gtk::TreeView::GRID_LINES_BOTH
    @view.enable_tree_lines = true
    @view.set_search_equal_func do |model,column,key,iter| 
      if Regexp.new(key) =~ iter[0]
        @view.scroll_to_cell(iter.path,nil,true,0.5,0.5)
        false
      else
        true
      end
    end

    @table.attach @header2[:Category] = Gtk::Label.new('Spell'), 0, 4, 0, 1, *ATCH
    @table.attach @header2[:Spell] = Gtk::Label.new('Category'), 4, 8, 0, 1, *ATCH
    @table.attach @header2[:Points] = Gtk::Label.new('Points'), 8, 10, 0, 1, *ATCH
    @table.attach Gtk::Label.new("Del"), 10, 11, 0, 1, *ATCH

    @win.add(@view)
    @win2.add_with_viewport(@table)
    @vbox.pack_start_defaults(@win)
    @vbox.pack_start_defaults(@win2)
    @vbox.show_all
    add(@vbox)
  end
end

class Cyberblock < Gtk::ScrolledWindow
  def initialize(app)
    @app = app
    super()
    self.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    @table = Gtk::Table.new(10, 4, homgenous = true)
    @cyber = {}
    @header1 = {}
    @header1[:Category] = [Gtk::Label.new('Category'), Gtk::ComboBox.new]

    @table.attach @header1[:Category][0], 0, 1, 0, 1, *ATCH
    add_with_viewport(@table)
  end
end

class Bioblock < Gtk::ScrolledWindow
  def initialize(app)
    @app = app
    super()
    self.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
  end
end

class Notebook < Gtk::Notebook
  attr_accessor :skill, :spell, :totem
  
  def initialize(app)
    @app = app
    super()
    #  @notebook=Gtk::Notebook.new
    @skill = Skillblock.new(@app)
    @spell = Spellblock.new(@app)
    @cyber = Cyberblock.new(@app)
    @bio = Bioblock.new(@app)
 #   @tview = SPELLVIEW.new(@app)
    append_page(@skill, Gtk::Label.new('Skills'))
    append_page(@cyber, Gtk::Label.new('Cyberware'))
    append_page(@bio, Gtk::Label.new('Bioware'))
    append_page(@spell, Gtk::Label.new('Spells'))
 #   append_page(@tview, Gtk::Label.new('txtv'))
    get_nth_page(3).sensitive = false
  end
end

a = Application.new
