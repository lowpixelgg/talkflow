loadstring(exports.houdini:import("*"))()
class = houdini.class
network = houdini.network
thread = houdini.thread

function table.toString(tbl, beautify, recLvl)
  if beautify == nil then beautify = true end
  recLvl = recLvl or 0
  local str = '{'..(beautify and '\n' or '')
  local kStr
  local vStr
  for k,v in pairs(tbl) do
      for i=0,recLvl do
          str = str..(beautify and '\t' or '')
      end
      kStr = (type(k) == 'string' and '"%s"' or '%s')
      kStr = (' ['..kStr..']'):format(k)
      vStr = (type(v) == 'table' and table.toString(v, beautify, recLvl+1) or v)
      str = str..kStr..' = '..vStr
  str = str..(next(tbl,k) and ',' or '')
      str = str..(beautify and '\n' or '')
  end
  if beautify then
      for i=1,recLvl do
          str = str..'\t'
      end
  end
  return str..'}'
end