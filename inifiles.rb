require 'Win32API'


$lstrlen = Win32API.new('kernel32', 'lstrlenA', %w(P), 'L');

$GetPrivateProfileString = Win32API.new('kernel32', 'GetPrivateProfileString', %w(P P P P L P), 'L');
$GetPrivateProfileString3I = Win32API.new('kernel32', 'GetPrivateProfileString', %w(I I I P L P), 'L');
$GetPrivateProfileString2I = Win32API.new('kernel32', 'GetPrivateProfileString', %w(P I I P L P), 'L');
$WritePrivateProfileString = Win32API.new('kernel32', 'WritePrivateProfileString', %w(P P P P), 'L');
$WritePrivateProfileString2I = Win32API.new('kernel32', 'WritePrivateProfileString', %w(P L L P), 'L');
$WritePrivateProfileString1I = Win32API.new('kernel32', 'WritePrivateProfileString', %w(P P L P), 'L');
$GetPrivateProfileInt = Win32API.new('kernel32', 'GetPrivateProfileString', %w(P P L P), 'L');
$GetPrivateProfileSection = Win32API.new('kernel32', 'GetPrivateProfileSection', %w(P P P P L P), 'L');
$WritePrivateProfileSection = Win32API.new('kernel32', 'WritePrivateProfileSection', %w(P P P P), 'L');


class Inifile
  INIBUFSIZE = 64*1024

  def initialize(f)
    @filename = f
  end
  
  #def FileName=(f)
  #  @filename = f
  #end
  #alias filename= FileName=
  
  def FileName
    @filename
  end
  alias filename FileName
  
  def ReadString(section, ident, defvalue='')
    s = ' ' * (INIBUFSIZE + 1)
    $GetPrivateProfileString.Call(section, ident, defvalue, s, INIBUFSIZE, @filename)
    l = $lstrlen.Call(s)
    if l == 0 then
      ''
    else
      s[0..l-1]
    end
  end
  alias readstring ReadString
  
  def WriteString(section, ident, value)
    $WritePrivateProfileString.Call(section, ident, value.to_s, @filename)
  end
  alias writestring WriteString

  def ReadInteger(section, ident, defvalue=0)
    $GetPrivateProfileInt.Call(section, ident, defvalue, @filename)
  end
  alias readinteger ReadInteger
  
  def WriteInteger(section, ident, value)
    writestring(section, ident, value.to_s)
  end
  alias writeinteger WriteInteger

  def ReadSections()
    s = ' ' * (INIBUFSIZE + 1)
    result = []
    if $GetPrivateProfileString3I.Call(0, 0, 0, s, INIBUFSIZE, @filename) != 0 then
      i = 0
      while s[0] != 0
        l = $lstrlen.Call(s)
        if l > 0 then
          ss = s[0..l-1]
          result[i] = ss
          s = s[l+1..-1]
          i += 1
        end
      end
    end
    result
  end
  alias readsections ReadSections
  
  def ReadSection(section)
    s = ' ' * (INIBUFSIZE + 1)
    result = []
    if $GetPrivateProfileString2I.Call(section, 0, 0, s, INIBUFSIZE, @filename) != 0 then
      i = 0
      while s[0] != 0
        l = $lstrlen.Call(s)
        if l > 0 then
          ss = s[0..l-1]
          result[i] = ss
          s = s[l+1..-1]
          i += 1
        end
      end
    end
    result
  end
  alias readsection ReadSection
  
  def ReadSectionValues(section)
    result = {}
    keys = self.ReadSection(section)
    if keys.length > 0 then
      keys.each {|key|
        result[key] = self.ReadString(section, key)
      }
    end
    result
  end
  alias readsectionvalues ReadSectionValues
  
  
  def EraseSection(section)
    $WritePrivateProfileString2I.Call(section, 0, 0, @filename)
  end
  alias erasesection EraseSection
  
  def DeleteKey(section, ident)
    $WritePrivateProfileString1I.Call(section, ident, 0, @filename)
  end
  alias deletekey DeleteKey
  
end


