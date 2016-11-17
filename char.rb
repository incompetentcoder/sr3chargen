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
  def load
  end

  def save
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

  def setmagetype(magetype)
    @basic.setmagetype(@a.setmagetype(magetype))
    setpointsrem
    setmagic
    setspellpoints
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

  def initialize
    @windows = Gtk::Window.new
    @a = Character.new(self)
    @guiattributes = Attributeblock.new(self)
    @basic = Mainblock.new(self)
    @notebook = Notebook.new(self)
    @table = Gtk::Table.new(9, 12, homogenous = false)
    @windows.add(@table)
    @table.attach @guiattributes, 0, 3, 4, 12
    @table.attach @basic, 0, 9, 0, 4, *ATCH
    @table.attach @notebook, 3, 9, 4, 12
    @table.n_columns = 9
    @table.n_rows = 12
    @windows.show_all
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
        {Points: 1, Specialization: special ? special : 0, Value: 1}
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

  def setmetatype(metatype)
    meta, points = metatype.active_text.split(':')
    pointsdiff = points.to_i - CONSTANT[:metatypes][@metatype][:Points]
    if checkpoints(pointsdiff)
      modpoints(pointsdiff)
      @metatype = meta.to_sym
      metatype.active
    else
      CONSTANT[:metatypes].find_index { |x| x[0] == @metatype }
    end
  end

  def setmagetype(magetype)
    mage, points = magetype.active_text.split(':')
    pointsdiff = points.to_i - CONSTANT[:magetypes][@magetype][:Points]
    if checkpoints(pointsdiff)
      modpoints(pointsdiff)
      @magetype = mage.to_sym
      magetype.active
    else
      CONSTANT[:magetypes].find_index { |x| x[0] == @magetype }
    end
  end

  def setmagic
    @special[:Magic] = @magetype == :None ? 0 : @special[:Essence]
  end
  
  def getmagetype
    @magetype
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
      CONSTANT[:nuyen].find_index(@nuyen)
    end
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
    @height = 120
    @weight = 50
    @nuyen = 5000
    @nuyenrem = 5000
    @activeskills = {}
    
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
      Age: [Gtk::Label.new('Age'), Gtk::SpinButton.new(15.0, 80.8, 1.0)],
      Gender: [Gtk::Label.new('Gender'), Gtk::ComboBox.new],
      Metatype: [Gtk::Label.new('Metatype'), Gtk::ComboBox.new],
      Magetype: [Gtk::Label.new('Magetype'), Gtk::ComboBox.new],
      Nuyen: [Gtk::Label.new('Nuyen'), Gtk::ComboBox.new],
      Nuyenrem: [Gtk::Label.new('¥ left'), Gtk::Label.new('¥')],
      Height: [Gtk::Label.new('Height'), Gtk::SpinButton.new(120.0, 200.0, 1.0)],
      Weight: [Gtk::Label.new('Weight'), Gtk::SpinButton.new(50.0, 200.0, 1.0)],
      Points: [Gtk::Label.new('Points'), Gtk::Label.new('120')],
      Pointsrem: [Gtk::Label.new('P left'), Gtk::Label.new('108')]
    }
    @elements[:Height][1].width_chars = 3
    @elements[:Weight][1].width_chars = 3
    @elements[:Age][1].width_chars = 2
    @elements[:Name][1].width_chars = 20
    @elements[:Streetname][1].width_chars = 20
    @elements[:Height][1].value = 170
    @elements[:Weight][1].value = 70
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
    @special[:Spellpoints].text = points.to_s
  end

  def setmagic(magic)
    @special[:Magic].text = magic.to_s
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

  def initialize(app)
    @app = app
    super()
    @table = Gtk::Table.new(10, 7, homogenous = true)
    @attributes = {}
    @derived = {}
    @special = {}
    @header = {}
    @table.attach @header[:Attributes] = Gtk::Label.new('Attributes'), 0, 3, 0, 1, *ATCH
    @table.attach @header[:Points] = Gtk::Label.new('Points'), 3, 5, 0, 1, *ATCH
    @table.attach @header[:RM] = Gtk::Label.new('RM'), 5, 6, 0, 1, *ATCH
    @table.attach @header[:BA] = Gtk::Label.new('BA'), 6, 7, 0, 1, *ATCH
    @table.attach @header[:CBM] = Gtk::Label.new('CB'), 7, 8, 0, 1, *ATCH
    @table.attach @header[:MM] = Gtk::Label.new('MM'), 8, 9, 0, 1, *ATCH
    @table.attach @header[:ACT] = Gtk::Label.new('AC'), 9, 10, 0, 1, *ATCH

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

    @table.attach Gtk::Label.new('Essence'), 6, 9, 18, 19, *ATCH
    @table.attach @special[:Essence] = Gtk::Label.new('6'), 9, 10, 18, 19, *ATCH
    @table.attach Gtk::Label.new('Body Index'), 6, 9, 19, 20, *ATCH
    @table.attach @special[:'Body Index'] = Gtk::Label.new('0'), 9, 10, 19, 20, *ATCH
    @table.attach Gtk::Label.new('Magic'), 6, 9, 20, 21, *ATCH
    @table.attach @special[:Magic] = Gtk::Label.new('0'), 9, 10, 20, 21, *ATCH
    @table.attach Gtk::Label.new('Spellpoints'), 6, 9, 21, 22, *ATCH
    @table.attach @special[:Spellpoints] = Gtk::Label.new('0'), 9, 10, 21, 22, *ATCH

    @table.attach Gtk::VSeparator.new, 5, 6, 18, 23, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 13, 14, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 17, 18, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 23, 24, *ATCH

    add(@table)
  end
end

class Skillblock < Gtk::ScrolledWindow

  def skilllvl(skill,data)
    @skillentries[skill][2].value = data[:Value]
    @skillentries[skill][3].text = 
      data[:Special] ? "#{data[:Value]-1}|#{data[:Value]-1}" : "#{data[:Value]}"
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
  end

  def initialize(app)
    @app = app
    super()
    @maintable = Gtk::Table.new(1,2)
    @table = Gtk::Table.new(12, 5, homogenous = true)
    @table2 = Gtk::Table.new(12,5, homogenous = true)
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

    @header[:ADD].signal_connect('clicked') do |x|
      @app.addskill(getattr,getskill,getspecial)
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
        @speccount = CONSTANT[:activeskills][getattr][x.active_text.to_sym].count
        @header[:ADD].sensitive = true
        CONSTANT[:activeskills][getattr][x.active_text.to_sym].each do |y|
          @header[:Specialization][1].append_text(y.to_s)
        end
      end
    end

    CONSTANT[:attributes].each do |x|
      @header[:Attribute][1].append_text(x.to_s)
    end

    @table.attach @header[:Attribute][0], 0, 3, 0, 1, *ATCH
    @table.attach @header[:Attribute][1], 0, 3, 1, 2, *ATCH
    @table.attach @header[:Skill][0], 3, 7, 0, 1, *ATCH
    @table.attach @header[:Skill][1], 3, 7, 1, 2, *ATCH
    @table.attach @header[:Specialization][0], 7, 11, 0, 1, *ATCH
    @table.attach @header[:Specialization][1], 7, 12, 1, 2, *ATCH
    @table.attach @header[:ADD], 11, 12, 0, 1, *ATCH
    @table.attach @header2[:Skill] = Gtk::Label.new('Skill'), 0, 4, 2, 3, *ATCH
    @table.attach @header2[:Specialization] = Gtk::Label.new('Specialization'), 4, 8, 2, 3, *ATCH
    @table.attach @header2[:Points] = Gtk::Label.new('Points'), 8, 10, 2, 3, *ATCH
    @table.attach @header2[:Value] = Gtk::Label.new('Value'), 10, 11, 2, 3, *ATCH
    @table.n_rows = 3
    @table.n_columns = 12
    @maintable.attach @table,0,1,0,1,*ATCH
    @maintable.attach @table2,0,1,1,2,*ATCH
    add_with_viewport(@maintable)
  end
end

class Spellblock < Gtk::ScrolledWindow
  def initialize(app)
    @app = app
    super()
    @table = Gtk::Table.new(10, 4, homogenous = true)
    @spells = {}
    @header1 = {}
    @header1[:Category] = [Gtk::Label.new('Category'), Gtk::ComboBox.new]
    @header1[:Spell] = [Gtk::Label.new('Spell'), Gtk::ComboBox.new]
    @header1[:Buttons] = [Gtk::Button.new('Add'), Gtk::Button.new('Del')]
    @table.attach @header1[:Category][0], 0, 4, 0, 1, *ATCH
    @table.attach @header1[:Category][1], 0, 4, 1, 2, *ATCH
    @table.attach @header1[:Spell][0], 4, 9, 0, 1, *ATCH
    @table.attach @header1[:Spell][1], 4, 9, 1, 2, *ATCH
    @table.attach @header1[:Buttons][0], 9, 10, 0, 1, *ATCH
    @table.attach @header1[:Buttons][1], 9, 10, 1, 2, *ATCH
    @header2 = {}
    @table.attach @header2[:Category] = Gtk::Label.new('Category'), 0, 3, 2, 3, *ATCH
    @table.attach @header2[:Spell] = Gtk::Label.new('Spell'), 3, 6, 2, 3, *ATCH
    @table.attach @header2[:Points] = Gtk::Label.new('Points'), 6, 8, 2, 3, *ATCH
    @table.attach @header2[:Force] = Gtk::Label.new('Force'), 8, 9, 2, 3, *ATCH
    @table.n_columns = 10
    @table.n_rows = 4
    add_with_viewport(@table)
  end
end

class Cyberblock < Gtk::ScrolledWindow
  def initialize(app)
    @app = app
    super()
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
  end
end

class Notebook < Gtk::Notebook
  attr_accessor :skill
  def initialize(app)
    @app = app
    super()
    #  @notebook=Gtk::Notebook.new
    @skill = Skillblock.new(@app)
    @spell = Spellblock.new(@app)
    @cyber = Cyberblock.new(@app)
    @bio = Bioblock.new(@app)
    append_page(@skill, Gtk::Label.new('Skills'))
    append_page(@cyber, Gtk::Label.new('Cyberware'))
    append_page(@bio, Gtk::Label.new('Bioware'))
    append_page(@spell, Gtk::Label.new('Spells'))
    get_nth_page(3).sensitive = false
  end
end

a = Application.new
