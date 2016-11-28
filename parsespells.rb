require 'pp'
require 'yaml'

f=File.read("spells").split("\n\n")
a={}
f.each do |x|
  lines=x.split("\n")
  name=lines[0].delete("@")
  a[name]={} unless a[name]
  start=1
  if lines[1][0] == "@"
    subname = lines[1].delete("@@")
    start=2
    a[name][subname]={}
  end

  headers=lines[start].split(" ˛ ").map {|x| x.to_sym}
  lines[start+1..-1].each do |c|
    spellname = c.split(" ˛ ")[0]
    if subname
      a[name][subname][spellname]={}
      a[name][subname][spellname][:Class] = name
      a[name][subname][spellname][:Subclass] = subname
    else
      a[name][spellname]={}
      a[name][spellname][:Class] = name
    end
    c.split(" ˛ ").each_with_index do |d,e|
      case d
      when /^\d+$/
        d=d.to_i
      when /\+|\-/
        d=d.to_s
      else
        d=d.to_sym
      end
      if subname
        a[name][subname][spellname][headers[e]] = d
      else
        a[name][spellname][headers[e]] = d
      end
    end
  end
  
    

end

File.open("spells.yaml","w+") << YAML.dump(a)


  
