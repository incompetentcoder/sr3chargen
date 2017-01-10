require 'gtk2'
require 'pp'
require 'pry'
require 'yaml'
require 'set'
require 'dentaku'

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
    if getpointsrem < 0
      errordialog("Invalid Character",getpointsrem)
      return
    end
    @a.remove_instance_variable(:@app)
    dialog=Gtk::FileChooserDialog.new("Save",nil,Gtk::FileChooser::ACTION_SAVE,nil,
                                      [Gtk::Stock::SAVE,Gtk::Dialog::RESPONSE_ACCEPT],
                                      [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL])
    dialog.run do |x|
      if x == Gtk::Dialog::RESPONSE_ACCEPT
        a = File.open(dialog.filename,'w+')
        a.write(YAML.dump(@a))
        a.close
        b = File.open(dialog.filename+".svg",'w+')
        b.write(makecharsheet)
        b.close
        c = GdkPixbuf::Pixbuf.new(file: "#{dialog.filename}.svg",width: 1402,height: 1815).save("#{dialog.filename}.png","png")
#        aspect = c.height.to_f/c.width.to_f
#        binding.pry
#        c.scale(Gdk.screen_height*1.25,Gdk.screen_height*1.25*aspect,Gdk::Pixbuf::INTERP_NEAREST).save(dialog.filename+".png","png")
      end
    end
    dialog.destroy
#    puts @a.to_yaml
    @a.setapp(self)
  end

  def makecharsheet
    a = File.open("test.svg").read
    getattributes.each do |x|
      temp = ""
      [:CM,:BM,:MM].each do |y|
        temp+="/#{x[1][:BA]+x[1][y]}" if x[1][y] > 0
      end
      temp+="/#{x[1][:ACT]}" unless temp.empty?
      a.sub!("attr#{x[0].to_s[0].downcase}","#{x[1][:BA]}#{temp}")
    end
    shit = {}
    getskills.each {|x| shit.merge!(x[1]) unless x[1].empty?}
    shit.each_with_index do |y,z|
      a.sub!("skill#{z+1}","#{y[0]} #{y[1][:Specialization]}")
      a.sub!("skill#{z+1}r","#{y[1][:Specialization] ? 
        (((y[1][:Value].to_i) -1).to_s + "/" + ((y[1][:Value].to_i) +1).to_s) : 
          y[1][:Value].to_i}")
    end
    getderived[:Pools].each do |x|
      a.sub!("#{x[0].to_s[0..2]}P","#{x[1]}")
    end
    [:Reaction,:Initiative].each do |x|
      getderived[x].each do |y|
        a.sub!("#{x.to_s[0]+y[0].to_s}:","#{x.to_s[0]+y[0].to_s}:#{y[1]}")
      end
    end
    [:Essence,:Magic].each do |x|
      a.sub!("special#{x.to_s[0].downcase}","#{getspecial[x]}")
    end
    a.sub!("insertname","#{getname}")
    a.sub!("insertstreetname","#{getstreetname}")
    a.sub!("insertage","#{getage.to_i}")
    a.sub!("insertsex","#{getgender == "Male" ? "♂" : "♀"}")
    a.sub!("insertrace","#{getmetatype}")
#    binding.pry
    temp = {}
    @a.getcyberware.each {|x| temp.merge!(x[1])}
    temp.first(7).each_with_index do |x,y|
      a.sub!("cyber#{y+1}<","#{x[0]}<")
      a.sub!("cyber#{y+1}r<","#{x[1][:Essence].round(2)}<")
    end
    @a.spells.first(8).each_with_index do |x,y|
      a.sub!("spell#{y+1}<","#{x[0]}<")
      a.sub!("spell#{y+1}f<","#{x[1][1].to_i}<")
      a.sub!("spell#{y+1}d<","#{x[1][0][:DTN].to_s.slice(0..2)+"|"+x[1][0][:DLVL].to_s.slice(0..2)}<")
    end

    a.gsub!(/(skill|cyber|bio|spell|power)\d{1,}(r|f|d|l|c)?</,"<")
    a
  end

  def gettotem
    @a.gettotem
  end

  def getage
    @a.age
  end

  def getgender
    @a.gender
  end

  def getattributes
    @a.attributes
  end

  def getskills
    @a.activeskills
  end

  def getderived
    @a.derived
  end

  def getspecial
    @a.special
  end

  def getname
    @a.name
  end
  
  def getstreetname
    @a.streetname
  end
  
  def getelement
    @a.getelement
  end

  def getessence
    @a.getessence
  end

  def updateessence
    @guiattributes.setessence(getessence)
    setmagic
  end
  
  def getpointsrem
    @a.getpointsrem
  end

  def getnuyenrem
    @a.getnuyenrem
  end

  def checkupdatecyberlvl(shorter,lvl,level,text,button,grade,option)
    array = lvlcalc(shorter,lvl,level,grade.split(':')[0])
    text.text = sclspretty(array)
    button.sensitive = checkmoneycyber(array) ? false : true
    button.sensitive = (button.sensitive? && checkspace(option,array[2])) if option
  end

  def checkspace(option,space)
    if option.empty?
      true
    else
      option.values[0][:Space].to_f.round(2) >= space.to_f.round(2)
    end
  end

  def lvlcalc(shorter,replace,level,grade)
    shortg = CONSTANT[:grades][grade.to_sym]
    level = (replace == "L" ? "1" : "25") unless level 
    [Dentaku(shorter[:Price].sub(/#{replace}/,level)+"*"+shortg[:Price].to_s).to_f.round,
     shorter[:Essence] ? 
    Dentaku(shorter[:Essence].sub(/#{replace}/,level)+"*"+shortg[:Essence].to_s).to_f.round(2) : 0,
    shorter[:ECU] ? 
    Dentaku(shorter[:ECU]).to_f.round(2) : nil]
  end

  def sclspretty(array)
    "Price: | #{array[0]} | Essence: #{array[1]}" + (array[2] ? " | ECU: #{array[2]}" : "")
  end

  def selectcyberlvl(cyber,lvl,shorter)
    b = c = d = nil
    case lvl
    when "Mp"
      text = "Select MP"
      adj = [25,500,25]
    when "L"
      text = "Select Level"
      adj = [1,shorter[:Maxlevel].to_i,1]
    end
    dialog = Gtk::Dialog.new(text,@windows,Gtk::Dialog::MODAL)
    dialog.action_area.layout_style=Gtk::ButtonBox::SPREAD
    spin = Gtk::SpinButton.new(*adj)
    dialog.vbox.add(Gtk::Label.new("#{cyber} : #{text}"))
    dialog.vbox.add(a = Gtk::Label.new("#{sclspretty(lvlcalc(shorter,lvl,nil,"Normal"))}"))
    grade = gradebox
    grade.active = 1
    dialog.vbox.add(grade)
    dialog.vbox.add(spin)
    ok = dialog.add_button("Ok",1)
    cancel = dialog.add_button("Cancel",-1)
    grade.signal_connect('changed') {|x| checkupdatecyberlvl(shorter,lvl,spin.value.to_s,a,ok,x.active_text,nil)}
    spin.signal_connect('value_changed') {|x| checkupdatecyberlvl(shorter,lvl,x.value.to_s,a,ok,grade.active_text,nil)}
    dialog.show_all
    dialog.run do |response|
      b = response
      c = spin.value.to_i.to_s
      d = grade.active_text.split(':')[0]
    end
    dialog.destroy
    [b,c,d]
  end

  def checkmoneycyber(array)
    array[0] > getnuyenrem || array[1] > getessence
  end

  def cybernamebaseincludes(cyber)
    shit = [] 
    cyber.each {|x| shit+= x[1].values.collect{|y| y[:Base]}.compact}
    cyber.each {|x| shit+= x[1].values.collect{|y| y[:Name]}.compact}
    cyber.each {|x| shit+= x[1].values.collect{|y| y[:Includes].split(",") if y[:Includes]}.compact}
    shit.flatten
  end

  def errordialog(error,data)
    dialog = 
      Gtk::MessageDialog.new(@windows, Gtk::Dialog::DESTROY_WITH_PARENT,
                             Gtk::MessageDialog::ERROR, Gtk::MessageDialog::BUTTONS_OK,
                             data ? "#{error}: #{data}" : "#{error}")
    GLib::Timeout.add(3000) { (dialog.response(Gtk::RESPONSE_OK) unless dialog.destroyed?) ? true : false }
    dialog.run if dialog
    dialog.destroy if dialog
  end

  def sidedialog(side,shorter)
    b = c = d = lvl = nil
    dialog=Gtk::Dialog.new("Choose side",@windows,Gtk::Dialog::MODAL)
    radio1 = Gtk::RadioButton.new("_Left")
    radio2 = Gtk::RadioButton.new(radio1,"_Right")
    dialog.vbox.add(Gtk::Label.new("Choose Side"))
    grade = gradebox
    grade.active = 1
    dialog.vbox.add(grade)
    dialog.vbox.add(a = Gtk::Label.new("#{sclspretty(lvlcalc(shorter,"L","1","Normal"))}"))
    dialog.vbox.add(radio1)
    dialog.vbox.add(radio2)
    ok = dialog.add_button("Ok",1)
    cancel = dialog.add_button("Cancel",-1)
    grade.signal_connect('changed') {|x| checkupdatecyberlvl(shorter,"L","1",a,ok,x.active_text,nil)}
    if side
      if side == "Left" 
        radio1.sensitive = false;radio2.active=true
      else
        radio2.sensitive = false;radio1.active=true
      end
    end
    dialog.show_all
    dialog.run do |response|
      b = response
      c = (radio1.active? ? radio1 : radio2).label[1..-1]
      d = grade.active_text.split(':')[0]
    end
    dialog.destroy
    [b,c,d]
  end

  def selectside(cyber)
    side = nil
    if @a.getcyberware["CY"]
      side = cybernameincludesside(cyber)
    end
    if side != "error"
      get = sidedialog(side,cyber)
      get[0] > 0 ? get[1..2] : nil
    else
      errordialog("already have cyberlimbs on both sides",nil)
      nil
    end
  end

  def cybernameincludesside(cyber)
    side = nil
    has = @a.getcyberware["CY"].select {|x,y| y[:Base] == "Cyberlimb" && x[/torso|skull/].nil?}
    has.each_pair do |x,y|
      unless (cyber[:Includes].split(',') & y[:Includes].split(',')).empty?
        if side && side != x.split(' ')[-1]
          return "error"
        else
          side = x.split(' ')[-1]
        end
      end
    end
    side
  end

  def gradedialog(shorter)
    b = c = nil
    dialog=Gtk::Dialog.new("Choose grade",@windows,Gtk::Dialog::MODAL)
    dialog.vbox.add(Gtk::Label.new("Choose grade"))
    grade = gradebox
    grade.active = 1
    dialog.vbox.add(grade)
    dialog.vbox.add(a = Gtk::Label.new("#{sclspretty(lvlcalc(shorter,"L","1","Normal"))}"))
    ok = dialog.add_button("Ok",1)
    cancel = dialog.add_button("Cancel",-1)
    grade.signal_connect('changed') {|x| checkupdatecyberlvl(shorter,"L","1",a,ok,x.active_text,nil)}
    dialog.show_all
    dialog.run do |response|
      b = response
      c = grade.active_text.split(':')[0]
    end
    dialog.destroy
    [b,c]
  end

  def checkhasoption(option,shorter)
    if option.empty?
      true
    elsif option.values[0][:Children]
      success = []
      option.values[0][:Children].each do |x|
        temp = {}
        @a.getcyberware.each {|y| temp.merge! y[1].select {|z,a| z == x}}
       # binding.pry
        success.push (temp[x][:Base] == shorter[:Base] || 
                      temp[x][:Name] == shorter[:Name])
      end
      !(success.include?(true))
    else
      true
    end
  end

  def checkpriceavail(item)
    err = ""
    if shorter[:Stats][:Price].to_i > getnuyenrem 
      err+="Insufficient Nuyen: #{shorter[:Stats][:Price]}\n"
    end
    if shorter[:Stats][:Avail].split('/')[0].to_i > 6
      err+="Availability too high: #{shorter[:Stats][:Avail]}\n"
    end
    return err
  end

  def getnumber(item,thing)
    num = thing.values.collect {|x| x[:Stats][:Name] == item.to_s}.compact.count+1
    num ? item = ("#{item} #{num}").to_sym : item
  end
      
  def setweapon(weapon)
    shorter = CONSTANT[:weapons][weapon]
    unless (err = checkpriceavail(shorter)).empty?
      errordialog(err,nil)
      return
    end
    actual = Marshal.load(Marshal.dump(shorter))
    weapon = getnumber(weapon,@a.weapons)
    @notebook.weapon.setweapon(actual,weapon)
    @a.addweapon(actual,weapon)
    setnuyenrem
   # binding.pry
  end

  def setarmor(armor)
    shorter = CONSTANT[:armors][armor]
    unless (err = checkpriceavail(shorter)).empty?
      errordialog(err,nil)
      return
    end
    actual = Marshal.load(Marshal.dump(shorter))
    armor = getnumber(armor,@a.armor)
    @notebook.armor.setarmor(actual,armor)
    @a.addarmor(actual,armor)
    setnuyenrem
  end
    

  def setcyber(cyber)
    level = lvl = side = place = grade = nil
    err = ""
    shorter = CONSTANT[:cyberware][cyber]
    installed = cybernamebaseincludes(@a.getcyberware)

    if shorter[:Conflicts]
      unless (conf = shorter[:Conflicts].split(",") & installed).empty?
        err+="Conflicts: #{conf}\n"
      end
    end
    if shorter[:Required]
      if (shorter[:Required].split(",") & installed).empty?
        err+="Required: #{shorter[:Required]}\n"
      elsif (shorter[:Option] && shorter[:Required][/hand|arm|foot|leg|limb/])
        temp = @a.getcyberware["CY"].select { |x,y| 
          ((y[:Includes].split(',')+[y[:Base]]) & shorter[:Required].split(','))[0] if y[:Base] == "Cyberlimb"}
        success = []
        success2 = []
        if shorter[:ECU]
          temp.each_pair {|x,y| success.push checkspace([{x => y}][0],shorter[:ECU])}
          err+="Not enough Space in any Limb: #{shorter[:ECU]}\n" unless success.include?(true)
        end
        temp.each_pair {|x,y| success2.push checkhasoption([{x => y}][0],shorter)}
        err+="Already have this option in all available limbs\n" unless success2.include?(true)
      end
    end
    if (Dentaku(shorter[:Price].sub(/Mp/,'25').sub(/L/,'1')) > getnuyenrem * 2)
      err+="Insufficient Money: #{getnuyenrem}\n"
    end
    if shorter[:Essence] && !(shorter[:Option] && (installed.include?(shorter[:Cyberlimb])))
      if (Dentaku(shorter[:Essence].sub(/Mp/,'25').sub(/L/,'1')) > getessence * 1.25)
        err+="Insufficient Essence: #{getessence}\n"
      end
    end
    if @a.getcyberware.collect {|x| x[1].values[0][:Name]}.include? cyber.to_s &&
        (cyber.to_s[/Cyberlimb/].nil? && cyber.to_s[/skull|torso/])
      err="Already installed: #{cyber}\n"
    end
    unless err.empty?
      errordialog(err,nil)
      return
    end
    if lvl = shorter[:Price][/Mp|L/]
      return unless (level = selectcyberlvl(cyber,lvl,shorter))[0] == 1
      grade = level[2]
    end
    if option = shorter[:Option]
 #     binding.pry
      if (cybernamebaseincludes(@a.getcyberware).include? shorter[:Cyberlimb])
        if shorter[:Cyberlimb][/eyes|ears|skull|torso/]
          parent = [1,shorter[:Cyberlimb]]
        else
          return unless (parent = placeoption(shorter))[0] == 1
          grade = parent[2]
          side = parent[1].keys[0]
          parent[1] = parent[1].values[0].keys[0]
        end
      end
    end
    if cyber.to_s.start_with?("Cyberlimb") && cyber.to_s[/torso|skull/].nil?
      return unless side = selectside(shorter)
      grade = side[1]
      side = side[0]
    end
    unless lvl || side || parent
      return unless (grade = gradedialog(shorter))
      grade = grade[1]
    end

    addcyber(shorter,cyber,level,lvl,side,parent,grade)
  end

  def gradebox
    a = Gtk::ComboBox.new
    a.append_text("Used: Price*0.5")
    a.append_text("Normal: no changes")
    a.append_text("Alpha: Price*2 | Essence*0.8 | Space*0.9")
    a
  end

  def sideincludes(limb,side,shorter)
    return false if limb.empty?
  #  binding.pry
    all = limb.values[0][:Includes].split(',') + [limb.values[0][:Base].to_s] +
      (limb.values[0][:Children] ? limb.values[0][:Children].map {|a| @a.getcyberware.collect {|x| 
      x[1].find {|y| y[0] == a}}.compact[0][1].values_at(:Base,:Name)}.flatten : [])
  #  binding.pry
    pp all
    !((all & shorter[:Required].split(',')).empty?)
  end

  def placeoption(shorter)
    b = c = d = nil
    dialog = Gtk::Dialog.new("Put option into limb?",@windows,Gtk::Dialog::MODAL)
    temp = @a.getcyberware["CY"].select {|x,y| y[:Name].start_with?("Cyberlimb")}
    sides = { "Left Arm" => temp.select {|x,y| (x[/arm|hand/] &&
                             x.split(" ")[-1] == "Left")},
              "Right Arm" => temp.select {|x,y| (x[/arm|hand/] && 
                             x.split(" ")[-1] == "Right")},
              "Left Leg" => temp.select {|x,y| (x[/leg|foot/] && 
                             x.split(" ")[-1] == "Left")},
              "Right Leg" => temp.select {|x,y| (x[/leg|foot/] && 
                             x.split(" ")[-1] == "Right")}}
    radios = [radio1 = Gtk::RadioButton.new("Left Arm: " + (sides["Left Arm"].empty? ? "" :
      "#{sides["Left Arm"].keys[0]} Space: #{sides["Left Arm"].values[0][:Space]}")),
    radio2 = Gtk::RadioButton.new(radio1,"Right Arm: " + (sides["Right Arm"].empty? ? "" :
      "#{sides["Right Arm"].keys[0]} Space: #{sides["Right Arm"].values[0][:Space]}")),
    radio3 = Gtk::RadioButton.new(radio1,"Left Leg: " + (sides["Left Leg"].empty? ? "" : 
      "#{sides["Left Leg"].keys[0]} Space: #{sides["Left Leg"].values[0][:Space]}")),
    radio4 = Gtk::RadioButton.new(radio1,"Right Leg: " + (sides["Right Leg"].empty? ? "" :
      "#{sides["Right Leg"].keys[0]} Space: #{sides["Right Leg"].values[0][:Space]}"))]
    dialog.vbox.add(Gtk::Label.new("Put option into limb?"))
    dialog.vbox.add(a = Gtk::Label.new("#{sclspretty(lvlcalc(shorter,"L","1","Normal"))}"))    
    grade = gradebox
    grade.active = 1
    dialog.vbox.add(grade)
    radios.each {|x| dialog.vbox.add(x)}
    ok = dialog.add_button("Ok",1)
    cancel = dialog.add_button("Cancel",-1)
    if shorter[:Required]
      radios.each do |x| 
        x.sensitive=false unless (sides[x.label.split(":")[0]].empty? ? false :
#        (((sides[x.label.split(":")[0]].values[0][:Includes].split(',') & shorter[:Required].split(","))[0] ||
#         ([sides[x.label.split(":")[0]].values[0][:Base].to_s] & shorter[:Required].split(","))[0]) &&
        (sideincludes(sides[x.label.split(':')[0]]," "+x.label.split(':')[0],shorter) &&
        checkspace(sides[x.label.split(":")[0]],shorter[:ECU].to_f) && checkhasoption(sides[x.label.split(":")[0]],shorter)))
      end
    end
    radios.each do |x|
      x.sensitive=false unless (checkspace(sides[x.label.split(":")[0]],shorter[:ECU].to_f) &&
        checkhasoption(sides[x.label.split(":")[0]],shorter))
    end
    (test = radios.find {|x| x.sensitive?}) ? test.active = true : (return [nil])
    grade.signal_connect('changed') {|x| checkupdatecyberlvl(shorter,"L","1",a,ok,x.active_text,nil)} 
    dialog.show_all
    dialog.run do |response|
      b = response
      c = sides.select {|x,y| x == radios[0].group.find {|x| x.active?}.label.split(':')[0]}
      d = grade.active_text.split(':')[0]
    end
    dialog.destroy
    [b,c,d]
  end

  def addcyber(shorter,cyber,level,lvl,side,parent,grade)
    actual = Marshal.load(Marshal.dump(shorter))
    if level
      [:Price,:Essence].each do |x|
        actual[x] = Dentaku(actual[x].sub(/#{lvl}/,level[1])).to_f.round(2) if actual[x]
      end
      tn,time = actual[:Avail].split("/")
      time = time.split(" ")
      actual[:Avail] = Dentaku(tn.sub(/#{lvl}/,level[1])).to_i.to_s + "/" +
        Dentaku(time[0].sub(/#{lvl}/,level[1])).to_i.to_s + " "+time[1]
    end
    if grade
      [:Price,:Essence,:Space].each do |x|
        actual[x] = Dentaku(actual[x]+"*"+CONSTANT[:grades][grade.to_sym][x].to_s).to_f.round(2) if actual[x]
      end
    end
    type = actual[:Type]
    @notebook.cyber.installcyber(actual,cyber,level,lvl,side,parent)
    @a.addcyber(actual,cyber,level,lvl,type,side,parent)
    setnuyenrem
    updateessence
  end

  def remcyber(cyber,name)
    temp = Marshal.load(Marshal.dump(@a.getcyberware))
    actual = err = ""
    temp.each {|x| actual = x[1].delete(cyber) if (x[1] && x[1][cyber])}
    if actual[:Children]
      err+="Options installed: #{actual[:Children]}\n"
    else
      temp.each do |w|
        w[1].each_pair do |x,y|
          if y[:Required]
            if (y[:Required].split(",") & cybernamebaseincludes(temp)).empty?
              err+="Required: #{y[:Required]}\n"
            end
          end
        end
      end
    end

    if err.empty?
      @a.remcyber(cyber,name)
      setnuyenrem
      updateessence
      true
    else
      errordialog(err,nil)
      false
    end
  end

  def remweapon(weapon)
    err = ""
   # binding.pry
    if ch = @a.weapons[weapon][:Stats][:Children]
      err+="Options installed: #{ch}\n"
      errordialog(err,nil)
      return false
    end
    @a.remweapon(weapon)
    setnuyenrem
    true
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

  def choosespelldialog(name,entry)
    a = nil
    b = nil
    type = name.sub(/.*(Attribute|Element|Sense|Skill|Life-Form|Object|Race).*/,'\1')
      
    if entry
      entered = Gtk::Entry.new
      entered.width_chars=30
    else
      index = case type
      when /Attr|Sens/
        CONSTANT[(type.to_s.downcase+'s').to_sym]
      when /Elem/
        CONSTANT[:elements].keys
      else
        @notebook.skill.skillentries.keys
      end
      return -1 if index.length < 1
    end

    dialog = Gtk::Dialog.new("Choose #{type}",@windows,Gtk::Dialog::MODAL)
    dialog.action_area.layout_style=Gtk::ButtonBox::SPREAD
    dialog.vbox.add(Gtk::Label.new("Choose #{type}"))
    if entry
      dialog.vbox.add(entered)
    else
      cb = Gtk::ComboBox.new
      index.each {|x| cb.append_text(x.to_s)}
      dialog.vbox.add(cb)
    end
    dialog.add_button("Ok",1)
    dialog.add_button("Cancel",-1)
    dialog.show_all
    dialog.run do |response|
      if entry
        a = name.sub(/#{type}/,"#{entered.text}")
      else
        a = name.sub(/#{type}/,"#{cb.active_text}")
      end
      b = response
    end

    dialog.destroy
    [b,a]
  end

  def appendspell(name,category,subcategory)
    case name
    when /\)/
      response,name2 = choosespelldialog(name,name =~ /Fo|Obj|Race/ ? true : false )
      return if response < 0
    else
      name2 = nil
    end
    if @a.appendspell(name.to_sym,category.to_sym,subcategory ? subcategory.to_sym : nil,name2 ? name2.to_sym : nil)
      @notebook.spell.appendspell(name2 ? name2 : name,category,subcategory)
    end
  end

  def checkspells(which,type)
    if @a.getmagetype =~ /ist/
      if which
        enablespells(which,type) unless @spellsenabled
      else
        disablespells if @spellsenabled
      end
    end
  end

  def dialogchoose(stuff,type)
    a = nil
    dialog = Gtk::Dialog.new("Choose #{type} Boni",@windows,Gtk::Dialog::MODAL)
    dialog.vbox.add(Gtk::Label.new("Choose #{type} Boni"))
    cb = Gtk::ComboBox.new
    dialog.vbox.add(cb)
    dialog.add_button("Ok",1)
    stuff.each_with_index do |x,y|
      if x[0].to_s =~ /1/
        CONSTANT[:spirits][:Nature][x[0][0...-1].to_sym].each_with_index do |a,b|
          cb.append_text(a.to_s+":"+x[1].to_s)
        end
      else
        cb.append_text(x.join(":"))
      end
    end
    cb.active = 0
    dialog.show_all
    dialog.run do |response|
      a = cb.active_text.split(":")
      a[0] = a[0].to_sym
      a[1] = a[1].to_i
    end
    dialog.destroy
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
    @a.settotem(totem,group,boni)
    totem = gettotem ? gettotem[0] : nil
    checkspells(totem,:totem)
    @guiattributes.nototem unless totem
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

  def setelement(element)
    @a.setelement(element)
    checkspells(element,:element)
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

  def getattr(attr,which)
    @a.attributes[attr][:Points]
  end

  def setattribute(attr, value)
    @guiattributes.setattribute(attr, @a.setattribute(attr, value.value.to_i))
    updateattr(attr) if getattr(attr,:Points) == value.value
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
    test = metatype.active_text.split(':')[0].to_sym
    @basic.setmetatype(@a.setmetatype(metatype))
    errordialog("Insufficient Points",getpointsrem) unless @a.getmetatype == test
    setmetamods
    setpointsrem
  end

  def enablespells(which=nil,type=nil)
    @notebook.get_nth_page(3).sensitive=true
    if which
      tot,grp,boni = type == :totem ? @a.gettotem : @a.getelement
      spells = boni[:spells].collect  {|x| x[0] if x[1] > 0}.compact
    else
      spells=CONSTANT[:spelltypes].keys
    end
    @notebook.spell.enablespells(spells)
    @spellsenabled = true
  end

  def disablespells
    @notebook.spell.clear
    @notebook.get_nth_page(3).sensitive=false
    @spellsenabled = false
  end

  def setmagetype(magetype)
    test = magetype.active_text.split(':')[0].to_sym
    @basic.setmagetype(@a.setmagetype(magetype))
    errordialog("Insufficient Points",getpointsrem) unless @a.getmagetype == test
    setpointsrem
    setmagic
    setspellpoints
    @a.getmagic && @a.getspellpoints > 0 && 
      !(@a.getmagetype =~ /^[^F].*ist|Conj/) ? enablespells : disablespells
    @a.getmagetype =~ /Shaman/ ? enabletotem : disabletotem
    @a.getmagetype == :Elementalist ? enableelement : disableelement
    if @a.getmagetype == :Shamanist
      @tooltips.set_tip(@windows,"Select a totem to be able to select spells",nil)
    elsif @a.getmagetype == :Elementalist
      @tooltips.set_tip(@windows,"Select element to be able to select spells",nil)
    else
      @tooltips.set_tip(@windows,nil,nil)
    end
  end

  def enabletotem
    @guiattributes.enabletotem
  end

  def disabletotem
    @guiattributes.disabletotem
  end

  def enableelement
    @guiattributes.enableelement
  end
  
  def disableelement
    @guiattributes.disableelement
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
    @spellsenabled = false
    @windows = Gtk::Window.new
    @windows2 = Gtk::ScrolledWindow.new
    @tooltips = Gtk::Tooltips.new
    @a = Character.new(self)
    @guiattributes = Attributeblock.new(self)
    @tooltips.set_tip(@guiattributes,"Set attribute values, select totem if shaman",nil)
    @basic = Mainblock.new(self)
    @tooltips.set_tip(@basic,"Input name and such, choose race/magetype from dropdown menus",nil)
    @notebook = Notebook.new(self)
    @tooltips.set_tip(@notebook,"Choose skills, spells if magetype with spellpoints, cyberware and gear in tabs",nil)
    @table = Gtk::Table.new(13, 12, homogenous = false)
    @windows.add(@windows2)
    @windows2.add_with_viewport(@table)
    updatepools
    updatereaction
    @table.attach @guiattributes, 0, 3, 4, 12
    @table.attach @basic, 0, 13, 0, 4, *ATCH
    @table.attach @notebook, 3, 13, 4, 12
    @table.n_columns = 13
    @table.n_rows = 12
    @windows.show_all
    @windows.signal_connect('destroy') {Gtk.main_quit}
    @windows.resize([Gdk.screen_width,@table.size_request[0]].min,[Gdk::screen_height,@table.size_request[1]].min)
    Gtk.init
    Gtk.main
  end
end

class Character
  attr_reader :name, :streetname, :age, :attributes,
              :points, :metatype, :magetype, :gender,
              :derived, :special, :activeskills, :weapons,
              :spells
  
  def getessence
    @special[:Essence]
  end

  def setapp(app)
    @app = app
  end

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

  def getelement
    @element
  end

  def getcyberware
    @cyberware
  end

  def addweapon(actual,weapon)
    @nuyenrem = @nuyenrem - actual[:Stats][:Price].to_i
    @weapons[weapon]=actual
  end

  def addarmor(actual,armor)
    @nuyenrem = @nuyenrem - actual[:Stats][:Price].to_i
    @armors[armor]=actual
  end

  def calcessenceoption(actual,parent,par)
    actual[:Essence] = actual[:Essence].to_f.round(2)
    if par == "SE"
      total = parent[:Children].inject(0) {|sum,x| sum + CONSTANT[:cyberware][x.to_sym][:Essence].to_f.round(2)}
      total = total.round(2)
      if total < 0.5
        if actual[:Essence] < (0.5 - total)
          actual[:Essence] = 0
        else
          actual[:Essence] = actual[:Essence] - (0.5 - total)
        end
      end
    else
      actual[:Essence] = 0 unless actual[:Type] == "CY"
    end
  end

  def addcyber(actual,cyber,level,lvl,type,side,parent)
    if parent
      if parent[1]
        actual[:Parent] = parent[1]
        par = parent[1].start_with?("Cyberlimb") ? "CY" : "SE"
#        @cyberware[par][parent[1]][:Children] = [] unless @cyberware[par][parent[1]][:Children]
#        calcessenceoption(actual,@cyberware[par][parent[1]],par)
#        @cyberware[par][parent[1]][:Children].push(cyber.to_s + (level ? " " + level[1] : "") + (side ? " " + side : ""))
        if actual[:ECU]
          @cyberware[par][parent[1]][:Space] = 
            (@cyberware[par][parent[1]][:Space].to_f - actual[:ECU].to_f).round(2).to_s
        end
        if actual[:Required]
          if (([@cyberware[par][parent[1]][:Base].to_s] + @cyberware[par][parent[1]][:Includes].split(',')) &
            actual[:Required].split(',')).empty?
            @cyberware[par][parent[1]][:Children].each do |a|
              @cyberware.each do |b| 
                temp = b[1].select {|c,d| c == a}.flatten
  #              binding.pry
                if temp[0] && [temp[1][:Name],temp[1][:Base]].include?(actual[:Required])
                  actual[:Required] = temp[0]
                  break
                end
              end
            end
          end
        end
        @cyberware[par][parent[1]][:Children] = [] unless @cyberware[par][parent[1]][:Children]
        calcessenceoption(actual,@cyberware[par][parent[1]],par)
        @cyberware[par][parent[1]][:Children].push(cyber.to_s + (level ? " " + level[1] : "") + (side ? " " + side : ""))
      end
    end
    @cyberware[type] = {} unless @cyberware[type]
    @cyberware[type][cyber.to_s + (level ? " " + level[1] : "") + (side ? " " + side : "")] = actual
    @special[:Essence] = (@special[:Essence] - actual[:Essence].to_f.round(2)).to_f.round(2)
    @nuyenrem -= actual[:Price].to_i
    if actual[:Stats]
      if actual[:Stats][:attributes]
        actual[:Stats][:attributes].each_pair do |x,y|
#          @attributes[x][y.keys[0]]+=y.values[0]
          @app.updateattr(x)
        end
      end
    end
    if actual[:Name].start_with? "Cyberlimb"
      [:Body,:Quickness,:Strength].each {|x| @app.updateattr(x)}
    end
  end

  def remcyber(cyber,name)
    type = CONSTANT[:cyberware][name.to_sym][:Type]
    if @cyberware[type][cyber][:Stats]
      if @cyberware[type][cyber][:Stats][:attributes]
        @cyberware[type][cyber][:Stats][:attributes].each_pair do |x,y|
          @attributes[x][y.keys[0]]-=y.values[0]
          @app.updateattr(x)
        end
      end
    end
    if p2 = @cyberware[type][cyber][:Parent]
      t2 = p2[/eyes|ears/] ? "SE" : "CY"
      @cyberware[t2][p2][:Children].delete(cyber)
      @cyberware[t2][p2].delete(:Children) if @cyberware[t2][p2][:Children].empty?
    end
    @nuyenrem += @cyberware[type][cyber][:Price].to_i
    (@special[:Essence] += @cyberware[type][cyber][:Essence].to_f.round(2)).to_f.round(2)
    @cyberware[type].delete(cyber)
    @cyberware.delete(type) if @cyberware[type].empty?
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


  def appendspell(name,category,subcategory,name2)
    if @spellpoints > 0
      @spells[name2 ? name2 : name] = [
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
            if @attributes[x[0]][:ACT] < x[1]
              @app.errordialog("Requirements not met",x)
              return false
            else
              return true
            end
          else
            if @derived[x[0]][:CBM] < x[1]
              @app.errordialog("Requirements not met",x)
              return false
            else
              return true
            end
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
  
  def setelement(element)
    if element == nil
      @element = nil
    else
      @element = [element,nil,CONSTANT[:elements][element]]
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
    attract = attrib == :Reaction ? @derived[:Reaction][:CBM] : @attributes[attrib][:ACT]
    current = @activeskills[attrib][skill][:Value]
    if value < current
      if current > attract
        if value > attract
          points = ((current - value) * -2)
        else
          points = (((current - attract) *-2) +
                    ((attract - value) *-1))
        end
      else
        points = ((current - value)*-1)
      end
    else
      if current > attract
        points = ((value - current)*2)
      else
        if value > attract
        points = (((value - attract) *2) +
                  ((attract - current) *1))
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
    @cyberware.find {|x| x[1].keys[0] =~ /Vehicle Control/}
  end

  def deck
  end

  def hasstat(thing,w,x,y,z)
    thing[w][x][y][z] if
    thing[w] && thing[w][x] && thing[w][x][y]
  end

  def cinit
    sum = 0
  #  all = @cyberware.collect {|x| x[1].values[0][:Stats][:derived][:Initiative][:CBM]}
  #  sum = all.inject(0) {|sum,x| sum + x}
    @cyberware.each {|x| sum += x[1].values.collect {|y| hasstat(y,:Stats,:derived,:Initiative,:CBM)}.compact.reduce(:+).to_i}
    sum
  end

  def binit
    sum = 0
  # all = @bioware.collect {|x| x[1].values[0][:Stats][:derived][:Initiative][:CBM]}
  # sum = all.inject(0) {|sum,x| sum + x}
    @bioware.each {|x| sum += x[1].values.collect {|y| hasstat(y,:Stats,:derived,:Initiative,:CBM)}.compact.reduce(:+).to_i}
    sum
  end

  def reaccbm
    reac = sumb = sumc = 0
    [:Intelligence,:Quickness].each do |x|
      [:BA,:CM,:BM,:MM]. each do |y|
        reac += @attributes[x][y]
      end
    end
    @bioware.each {|x| sumb += x[1].values.collect {|y| hasstat(y,:Stats,:derived,:Reaction,:CBM)}.compact.reduce(:+).to_i}
    @cyberware.each {|x| sumc += x[1].values.collect {|y| hasstat(y,:Stats,:derived,:Reaction,:CBM)}.compact.reduce(:+).to_i}
    (reac/2 + sumb + sumc).floor
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
    if vcr
      @derived[:Pools][:'Control Pool'] = @derived[:Reaction][:Rigg]
    else
      @derived[:Pools][:'Control Pool'] = 0
    end
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
    moneydiff = (@nuyen - @nuyenrem) < money
    if checkpoints(pointsdiff) && moneydiff
      modpoints(pointsdiff)
      diff = @nuyen - @nuyenrem
      @nuyen = money
      @nuyenrem = @nuyen - diff
      nuyen.active
    else
      err = ""
      err+="Insufficient Points\n" unless checkpoints(pointsdiff)
      err+="New nuyen < already spent\n" unless moneydiff
      @app.errordialog(err,nil)
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

  def getpointsrem
    @pointsrem
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

  def updatecm(a,attr)
    mod1 = mod2 = total = 0.0
    limbs = []
    halflimbs = []
    @cyberware.each {|x| mod2 += x[1].values.collect {|y| hasstat(y,:Stats,:attributes,attr,:CM)}.compact.reduce(:+).to_i}
    case attr
    when :Strength
      limbs = @cyberware["CY"].collect {|x| x[1] if x[0] =~ /Cyberlimb Cyber(arm|leg)/}.compact if @cyberware["CY"]
      total = limbs.inject(0) do |sum,x|
        if x[:Children] && test = x[:Children].find {|y| y=~/Strength.*plus/}
          sum + test[/\d/].to_i
        elsif x[:Children] && test = x[:Children] && x[:Children].find {|y| y=~/Strength.*/}
          sum + test[/\d/].to_i
        else
          sum + 0
        end if limbs
      end 
      mod1 = ((limbs.count * (4+a[:RM].to_f - a[:BA].to_f) + total.to_f)/4)    
      mod2*(1-limbs.count/4) + mod1

    when :Body
      limbs = @cyberware["CY"].collect {|x| x[1] if x[0] =~ /Cyberlimb Cyber(arm|leg|torso)/}.compact if @cyberware["CY"]
      halflimbs = @cyberware["CY"].collect {|x| x[1] if x[0] =~ /Cyberlimb Cyber(fore|hand|foot|skull)/}.compact if @cyberware["CY"]
      mod1 = limbs.count/2 + halflimbs.count/4
      mod2 - ((meh = limbs.count + halflimbs.count/2) > 2 ? (meh-2) : 0) + mod1

    when :Quickness
      limbs = @cyberware["CY"].collect {|x| x[1] if x[0] =~ /Cyberlimb Cyber(arm|leg)/}.compact if @cyberware["CY"]
      total = limbs.inject(0) do |sum,x|
        if x[:Children] && test = x[:Children].find {|y| y=~/Quickness.*plus/}
          sum + test[/\d/].to_i
        elsif x[:Children] && test = x[:Children] && x[:Children].find {|y| y=~/Quickness.*/}
          sum + test[/\d/].to_i
        else
          sum + 0
        end
      end if limbs
      mod1 = ((limbs.count * (4+a[:RM].to_f - a[:BA].to_f) + total.to_f)/4)
      mod2 + mod1

    end
  end

  def updatebm(a,attr)
  end

  def updatemm(a,attr)
  end


  def updateattr(attr)
    if [:Body,:Quickness,:Strength].include?(attr)
      a = @attributes[attr]
      a[:CM] = updatecm(a,attr).to_i
      a[:BM] = updatebm(a,attr).to_i
      a[:MM] = updatemm(a,attr).to_i
    end

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
    if value.even?
      if (value / 2 + @attributes[attr][:RM] > 0)
        if checkpoints(value - @attributes[attr][:Points])
          if @app.checkskills(attr,@attributes[attr][:ACT]-@attributes[attr][:BA]+
              value/2+@attributes[attr][:RM],@attributes[attr][:ACT])
            modpoints(value - @attributes[attr][:Points])
            @attributes[attr][:Points] = value
          end
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

  def remweapon(weapon)
    @nuyenrem += @weapons[weapon][:Stats][:Price].to_i
    @weapons.delete(weapon)
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
    @element = nil 
    @cyberware = {}
    @bioware = {}
    @gear = {}
    @weapons = {}
    @armors = {}
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
    @activeskills[:Reaction]={}
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
    @elements[:Age][1].value = 15
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

  def setessence(essence)
    @special[:Essence][1].text = essence.round(2).to_s
  end

  def setmagic(magic)
    @special[:Magic][1].text = magic.floor.to_s
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

  def enableelement
    @element.each {|x| x.sensitive = true}
    @totem[5].sensitive = true
    @totem[7].sensitive = true
    if not @elementenabled
      CONSTANT[:elements].each_key {|x| @element[1].append_text(x.to_s)}
      @elementenabled = 1
    end
    @element[1].active = -1
  end

  def disableelement
    @element.each do |x|
      x.active = -1 if x.class == Gtk::ComboBox
      x.sensitive = false
    end
    @totem[5].sensitive = false
    @totem[7].sensitive = false
    @tooltips.set_tip(@element[1],nil,nil)
    4.times {|x| @element[1].remove_text(0)}
    @elementenabled = nil
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
        boni[2][:spells].collect {|x| "#{x[0]}:#{x[1]}"}.join(", ") : ""
      @totem[7].text = boni[2][:spirits] ? 
        boni[2][:spirits].collect {|x| "#{x[0]}:#{x[1]}"}.join(", ") : ""
      @totem[5].sensitive=true
      @totem[7].sensitive=true
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
    @element = []
    @totemcount = 0
    @table.attach @element[0] = Gtk::Label.new('Element'),0,3,24,26,*ATCH
    @table.attach @element[1] = Gtk::ComboBox.new,3,10,24,26,*ATCH
    @table.attach @totem[0] = Gtk::Label.new('Type'),0,3,26,28,*ATCH
    @table.attach @totem[1] = Gtk::ComboBox.new,3,10,26,28,*ATCH
    @table.attach @totem[2] = Gtk::Label.new('Totem'),0,3,28,30,*ATCH
    @table.attach @totem[3] = Gtk::ComboBox.new,3,10,28,30,*ATCH
    @table.attach @totem[4] = Gtk::Label.new('Spells'),0,10,30,31,*ATCH
    @table.attach @totem[5] = Gtk::Label.new(''),0,10,31,33,*ATCH
    @table.attach @totem[6] = Gtk::Label.new('Spirits'),0,10,33,34,*ATCH
    @table.attach @totem[7] = Gtk::Label.new(''),0,10,34,36,*ATCH
    @totem[5].wrap = true
    @totem[5].justify = Gtk::JUSTIFY_FILL 
    @totem[5].width_chars = 40
    @totem[7].wrap = true
    @totem[7].justify = Gtk::JUSTIFY_FILL
    @totem[7].width_chars = 40

    @totem.each {|x| x.sensitive=false}
    @element.each {|x| x.sensitive=false}

    @element[1].signal_connect('changed') do |x|
      if x.active_text
        temp = CONSTANT[:elements][x.active_text.to_sym]
        @tooltips.set_tip(@element[1],temp[:desc],nil)
        @app.setelement(x.active_text.to_sym)
      else
        @tooltips.set_tip(@element[1],nil,nil)
        @app.setelement(nil)
      end
      settotemboni(@app.getelement)
    end
    
    @totem[1].signal_connect('changed') do |x|
      cleartotems
      if x.active_text
        @app.availabletotems(x.active_text.to_sym)
      end
    end

    @totem[3].signal_connect('changed') do |x|
      if x.active_text
        temp = CONSTANT[:totems][@totem[1].active_text.to_sym][x.active_text.to_sym]
        @tooltips.set_tip(@totem[3],(temp[:desc] ? "#{temp[:desc]}\n" : '')+
          (temp[:properties] ? temp[:properties] : ''),nil)
        @app.settotem(x.active_text.to_sym,@totem[1].active_text.to_sym)
      else
        @tooltips.set_tip(@totem[3],'',nil)
        @app.settotem(nil,nil) unless @app.gettotem == nil
      end
#      x.active = -1 unless @app.gettotem
      settotemboni(@app.gettotem)
    end
    add(@table)
  end
end

class Skillblock < Gtk::ScrolledWindow
  attr_accessor :skills, :skillentries

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
    @header[:Attribute][1].append_text("Reaction")

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
    newspell unless @spells.empty?
    @view.collapse_all
    @allowed = spells
    @spells = {}
  end

  def spelllvl(name,value)
    @spells[name][2].value = value
  end
  
  def clear(which=nil)
    newspell unless @spells.empty?
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
      Gtk::Label.new(name),Gtk::Label.new(subcategory ? "#{category}/#{subcategory}" : category),
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
    @header = {}
    @model = Gtk::TreeStore.new(String, String, String, String, String, String, String, String, String)
    @model.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view = Gtk::TreeView.new(@model)
    @order = {}
    %i(Name Dur Range Area DTN DLVL Damage DamType Element).each_with_index do |a,b|
      @order[a]=b
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
#      unless (CONSTANT[:spelltypes].keys + CONSTANT[:subspelltypes][:Manipulation] +
#          CONSTANT[:subspelltypes][:Illusion]).include? name.to_sym
      if @model.get_iter(b)[1]
        if b.depth == 3
          b.up!
          subcategory = @model.get_iter(b)[0]
        end
        b.up!
        category = @model.get_iter(b)[0]
        @app.appendspell(name,category,subcategory) unless @spells[name]
      else
        a.row_expanded?(b) ? a.collapse_row(b) : a.expand_row(b,false)
      end
    end 

    (0..8).each do |x|
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
      col.set_sizing  Gtk::TreeViewColumn::AUTOSIZE
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

    @table.attach @header[:Category] = Gtk::Label.new('Spell'), 0, 4, 0, 1, *ATCH
    @table.attach @header[:Spell] = Gtk::Label.new('Category'), 4, 8, 0, 1, *ATCH
    @table.attach @header[:Points] = Gtk::Label.new('Points'), 8, 10, 0, 1, *ATCH
    @table.attach Gtk::Label.new("Del"), 10, 11, 0, 1, *ATCH

    @win.add(@view)
    @win2.add_with_viewport(@table)
    @vbox.pack_start_defaults(@win)
    @vbox.pack_start_defaults(@win2)
    @vbox.show_all
    add(@vbox)
  end
end

class Cyberblock < Gtk::Frame
  def addcyber(parent,rows,bases)
    children = Hash.new
    bases.each do |x|
      children[x] = @model.append(parent)
      children[x][0] = x
    end
    rows.values.each do |a|
      if a[:Base] 
        child = @model.append(children[a[:Base]])
      else
        child = @model.append(parent)
      end
      a.each_pair do |b,c|
        child[@order[b]] = c.to_s if @order[b]
      end
    end
  end

  def installcyber(actual,cyber,level,lvl,side,parent)
    child = nil
    if parent && parent[1]
      pp parent[1]
      @model2.each {|x,y,z| child = @model2.append(z) if z[0] == parent[1]}
    else
      child = @model2.append(nil)
    end
    actual.each_pair do |b,c|
      child[@order[b]] = c.to_s if @order[b]
    end
    child[8] = child[0]
    child[0] = cyber.to_s + (level ? " " + level[1] : "") + (side ? " " + side : "")
#    binding.pry
  end

  def initialize(app)
    @app = app
    super()
    @win = Gtk::ScrolledWindow.new
    @win2 = Gtk::ScrolledWindow.new
    @vbox = Gtk::VBox.new(true,nil)
    @cyber = {}
    @model = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String)
    @model.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view = Gtk::TreeView.new(@model)
    @model2 = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String)
    @model2.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view2 = Gtk::TreeView.new(@model2)
    @order = {}
    %i(Name Essence Price Conceal Legality Avail Required Conflicts).each_with_index do |x,y|
      @order[x]=y
    end

    %i(Brainware Senseware Commware Matrixware Riggerware Bodyware Cyberlimb).each do |x|
      parent = @model.append(nil)
      parent[0] = x
      cyber = CONSTANT[:cyberware].find_all {|y| y[1][:Type] =~ /#{x[0..1].upcase}/}.to_h
      bases = cyber.collect {|y| y[1][:Base] unless y[1][:Base] == ""}.compact.to_set
      addcyber(parent,cyber,bases)
    end
    
    (0..7).each do |x|
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
      col.set_sizing Gtk::TreeViewColumn::AUTOSIZE
      @view.append_column(col)
      if x < 6
        col2 = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
        col.set_sizing Gtk::TreeViewColumn::AUTOSIZE
        @view2.append_column(col2)
      end
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

    @view.signal_connect('row-activated') do |a,b,c|
      if @model.get_iter(b)[2]
        @app.setcyber(@model.get_iter(b)[0].to_sym)
      else
        a.row_expanded?(b) ? a.collapse_row(b) : a.expand_row(b,false)
      end
    end

    @view2.signal_connect('row-activated') do |a,b,c|
      if @app.remcyber(@model2.get_iter(b)[0],@model2.get_iter(b)[8])
        @model2.remove(@model2.get_iter(b))
      end
    end

    @win2.add(@view2)
    @win.add(@view)
    @vbox.pack_start_defaults(@win)
    @vbox.pack_start_defaults(@win2)
    @vbox.show_all
    add(@vbox)
  end
end

class Bioblock < Gtk::Frame
  def initialize(app)
    @app = app
    super()
    @win = Gtk::ScrolledWindow.new
    @win2 = Gtk::ScrolledWindow.new
    @vbox = Gtk::VBox.new(true,nil)
    @bio = {}
    @model = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String)
    @view = Gtk::TreeView.new(@model)
    @order = %w(Name Bioindex Price Conceal Legality Avail Required Conflicts)

    add(@vbox)
  end
end

class Powerblock < Gtk::Frame
  def initialize(app)
    @app = app
    super()
    @win = Gtk::ScrolledWindow.new
    @win2 = Gtk::ScrolledWindow.new
    @vbox = Gtk::VBox.new(true,nil)
    @powers = {}
    @model = Gtk::TreeStore.new(String,String,String,String,String,String,String)
    @view = Gtk::TreeView.new(@model)
    @order = %w(Name Cost Levels Required Conflicts)
    
    add(@vbox)
  end
end

class Weaponblock < Gtk::Frame
  
  def addweps(parent,rows,bases)
    children = Hash.new
    unless bases.empty?
      bases.each do |x|
        children[x] = @model.append(parent)
        children[x][0] = x
      end
    end
    rows.each do |a|
      if par=a[1][:Type][2]
        child = @model.append(children[par])
      else
        child = @model.append(parent)
      end
      a[1][:Stats].each_pair do |b,c|
        child[@order[b]] = c.to_s if @order[b]
      end
    end
  end

  def setweapon(actual,weapon)
    child = @model2.append(nil)
    actual[:Stats].each_pair do |b,c|
      child[@order[b]] = c.to_s if @order[b]
    end
    child[0]=weapon.to_s
  end

  def initialize(app)
    @app = app
    super()
    @tooltips = Gtk::Tooltips.new
    @win = Gtk::ScrolledWindow.new
    @win2 = Gtk::ScrolledWindow.new
    @vbox = Gtk::VBox.new(true,nil)
    @weapons = {}
    @model = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String,String)
    @model.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view = Gtk::TreeView.new(@model)
    @model2 = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String,String)
    @model2.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view2 = Gtk::TreeView.new(@model2)
    @order = {}
    %i(Name Range Conc. Ammo Mode Damage Price Legality Avail Extras).each_with_index do |x,y|
      @order[x]=y
    end
    CONSTANT[:weapons].collect{|x| x[1][:Type][1]}.compact.to_set.each do |x|
      parent = @model.append(nil)
      parent[0] = x
      weaps = CONSTANT[:weapons].find_all {|y| y[1][:Type][1] == x}
      bases = weaps.collect {|y| y[1][:Type][2]}.compact.to_set
      addweps(parent,weaps,bases)
    end

    (0..8).each do |x|
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
      col.set_sizing Gtk::TreeViewColumn::AUTOSIZE
      @view.append_column(col)
      col2 = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
      col.set_sizing Gtk::TreeViewColumn::AUTOSIZE
      @view2.append_column(col2)
    end
    @view.enable_grid_lines = Gtk::TreeView::GRID_LINES_BOTH
    @view.enable_tree_lines = true
   # @view.tooltip_column = 9
    @view.has_tooltip = true
    @view.set_search_equal_func do |model,column,key,iter| 
      if Regexp.new(key) =~ iter[0]
        @view.scroll_to_cell(iter.path,nil,true,0.5,0.5)
        false
      else
        true
      end
    end

    @view.signal_connect('query_tooltip') do |a,b,c,d,e|
      if bleh = a.get_path(*a.convert_widget_to_bin_window_coords(b,c))
        meh = @model.get_iter(bleh[0])[9].to_s
        meh == "" ? false : e.set_text(meh)
      end
    end
    
    @view.signal_connect('row-activated') do |a,b,c|
      if @model.get_iter(b)[2]
        @app.setweapon(@model.get_iter(b)[0].to_sym)
      else
        a.row_expanded?(b) ? a.collapse_row(b) : a.expand_row(b,false)
      end
    end

    @view2.signal_connect('row-activated') do |a,b,c|
      if @app.remweapon(@model2.get_iter(b)[0].to_sym)
        @model2.remove(@model2.get_iter(b))
      end
    end

    
    @win2.add(@view2)
    @win.add(@view)
    @vbox.pack_start_defaults(@win)
    @vbox.pack_start_defaults(@win2)
    @vbox.show_all
    add(@vbox)
  end
end

class Gearblock < Gtk::Frame
  def initialize(app)
    @app = app
    super()
    @win = Gtk::ScrolledWindow.new
    @win2 = Gtk::ScrolledWindow.new
    @vbox = Gtk::VBox.new(true,nil)
    @gear = {}
    @model = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String)
    @model.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view = Gtk::TreeView.new(@model)
    @model2 = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String)
    @model2.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view2 = Gtk::TreeView.new(@model2)
    @order = {}
    %i(Name Range Conc. Ammo Mode Damage Price Legality Avail).each_with_index do |x,y|
      @order[x]=y
    end
  end

end

class Armorblock < Gtk::Frame
  
  def addarmors(model,armors)
    armors.each do |a|
      child = model.append(nil)
      a[1][:Stats].each_pair do |b,c|
        child[@order[b]] = c.to_s if @order[b]
      end
    end
  end

  def setarmor(actual,armor)
    child = @model2.append(nil)
    actual[:Stats].each_pair do |b,c|
      child[@order[b]] = c.to_s if @order[b]
    end
    child[0]=armor.to_s
  end

  def initialize(app)
    @app = app
    super()
    @tooltips = Gtk::Tooltips.new
    @win = Gtk::ScrolledWindow.new
    @win2 = Gtk::ScrolledWindow.new
    @vbox = Gtk::VBox.new(true,nil)
    @armor = {}
    @model = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String,String)
    @model.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view = Gtk::TreeView.new(@model)
    @model2 = Gtk::TreeStore.new(String,String,String,String,String,String,String,String,String,String)
    @model2.set_sort_column_id(0,Gtk::SORT_ASCENDING)
    @view2 = Gtk::TreeView.new(@model2)
    @order={}
    %i(Name Rating Conc. Weight Price Legality Avail).each_with_index do |x,y|
      @order[x]=y
    end
    addarmors(@model,CONSTANT[:armors])

    (0..6).each do |x|
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
      col.set_sizing Gtk::TreeViewColumn::AUTOSIZE
      @view.append_column(col)
      col2 = Gtk::TreeViewColumn.new("#{@order.rassoc(x)[0]}",renderer, :text => x)
      col.set_sizing Gtk::TreeViewColumn::AUTOSIZE
      @view2.append_column(col2)
    end
    @view.enable_grid_lines = Gtk::TreeView::GRID_LINES_BOTH
    @view.enable_tree_lines = true
   # @view.tooltip_column = 9
    @view.has_tooltip = true
    @view.set_search_equal_func do |model,column,key,iter| 
      if Regexp.new(key) =~ iter[0]
        @view.scroll_to_cell(iter.path,nil,true,0.5,0.5)
        false
      else
        true
      end
    end



    @win2.add(@view2)
    @win.add(@view)
    @vbox.pack_start_defaults(@win)
    @vbox.pack_start_defaults(@win2)
    @vbox.show_all
    add(@vbox)
  end
end


class Notebook < Gtk::Notebook
  attr_accessor :skill, :spell, :totem, :cyber, :weapon, :gear
  
  def initialize(app)
    @app = app
    super()
    #  @notebook=Gtk::Notebook.new
    @skill = Skillblock.new(@app)
    @spell = Spellblock.new(@app)
    @cyber = Cyberblock.new(@app)
    @bio = Bioblock.new(@app)
    @weapon = Weaponblock.new(@app)
    @armor = Armorblock.new(@app)
    @gear = Gearblock.new(@app)
 #   @tview = SPELLVIEW.new(@app)
    append_page(@skill, Gtk::Label.new('Skills'))
    append_page(@cyber, Gtk::Label.new('Cyberware'))
    append_page(@bio, Gtk::Label.new('Bioware'))
    append_page(@spell, Gtk::Label.new('Spells'))
    append_page(@weapon, Gtk::Label.new('Weapons'))
    append_page(@armor, Gtk::Label.new('Armor'))
    append_page(@gear, Gtk::Label.new('Gear'))
 #   append_page(@tview, Gtk::Label.new('txtv'))
    get_nth_page(3).sensitive = false
  end
end

a = Application.new
