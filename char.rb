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

  def setattribute(attrib, value)
    pp attrib, value
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
    @guiattributes.updateattr(attr,@a.updateattr(attr))
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

  def setmetatype(metatype)
    meta,points = metatype.active_text.split(":")
    pointsdiff = points.to_i - CONSTANT[:metatypes][@metatype][:Points]
    if checkpoints(pointsdiff)
      modpoints(pointsdiff)
      @metatype = meta.to_sym
      metatype.active
    else
      CONSTANT[:metatypes].find_index(@metatype)
    end
  end

  def setmagetype(magetype)
    mage,points = magetype.active_text.split(":")
    pointsdiff = points.to_i - CONSTANT[:magetypes][@magetype][:Points]
    if checkpoints(pointsdiff)
      modpoints(pointsdiff)
      @magetype = mage.to_sym
      magetype.active
    else
      CONSTANT[:magetypes].find_index(@magetype)
    end
  end

  def setnuyen(nuyen)
    money,points = nuyen.active_text.split(":").map {|x| x.to_i}
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
    @attributes[attr][:ACT] = @attributes[attr][:BA] + @attributes[attr][:CM] +
      @attributes[attr][:BM] + @attributes[attr][:MM]
    @attributes[attr]
  end

  def setmetamods
    CONSTANT[:metatypes][@metatype][:Racialmods].each_pair do |x,y|
      @attributes[x][:BA] = @attributes[x][:Points]/2 + y
      if (y > @attributes[x][:RM]) && (@attributes[x][:RM] < 0)
        diff = y - @attributes[x][:RM]
        @attributes[x][:Points] -= diff*2
        @attributes[x][:BA] -= diff
        modpoints(diff*-2)
      end
      if @attributes[x][:BA] <= 0
        diff = 1 + @attributes[x][:BA].abs
        @attributes[x][:BA] += diff
        @attributes[x][:Points] += diff*2
        modpoints(diff*2)
      end
      @attributes[x][:RM]=y
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
    @attributes = {}
    CONSTANT[:attributes].each do |x|
      @attributes[x] = {}
      CONSTANT[:attrinfo].each do |y|
        @attributes[x][y] = case y
                            when :BA
                              1
                            when :Points
                              2
                            when :ACT
                              1
                            else
                              0
                            end
      end
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

  def updateattr(attr,datablock)
    @attributes[attr][:RM].text = datablock[:RM].to_s
    @attributes[attr][:BA].text = datablock[:BA].to_s
    @attributes[attr][:CBM].text = (datablock[:CM] + datablock[:BM]).to_s
    @attributes[attr][:MM].text = datablock[:MM].to_s
    @attributes[attr][:ACT].text = datablock[:ACT].to_s
    @attributes[attr][:Points].value = datablock[:Points]
  end

  def setspellpoints(points)
    @special[:Spellpoints].text = points.to_s
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
    @table.attach @special[:Spellpoints] = Gtk::Label.new('0'), 9, 10 , 21, 22, *ATCH

    @table.attach Gtk::VSeparator.new, 5, 6, 18, 23, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 13, 14, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 17, 18, *ATCH
    @table.attach Gtk::HSeparator.new, 0, 10, 23, 24, *ATCH

    add(@table)
  end
end

class Skillblock < Gtk::ScrolledWindow
  def initialize(app)
    @app = app
    super()
    @table = Gtk::Table.new(12, 5, homogenous = true)
    @skills = {}
    @header = {}
    @header2 = {}
    @header[:Attribute] = [Gtk::Label.new('Attribute'), Gtk::ComboBox.new]
    @header[:Skill] = [Gtk::Label.new('Skill'), Gtk::ComboBox.new]
    @header[:Specialization] = [Gtk::Label.new('Specialization'), Gtk::ComboBox.new]
    @header[:ADD] = Gtk::Button.new('Add')

    @header[:Attribute][1].signal_connect('changed') do |x|
      @header[:Skill][1].active = 0
      i = 0
      while @header[:Skill][1].active_text != NIL
        @header[:Skill][1].remove_text(i)
        @header[:Skill][1].active += 1
      end
      @header[:Skill][1].active = -1
      CONSTANT[:activeskills][x.active_text.to_sym].each do |y|
        @header[:Skill][1].append_text(y.to_s)
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
    @table.attach @header2[:Value] = Gtk::Label.new('Value'), 10, 12, 2, 3, *ATCH
    @table.n_rows = 4
    @table.n_columns = 12
    add_with_viewport(@table)
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
  #  attr_accessor self
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
