local moucaopiwin = fk.CreateSkill {
  name = "os_mou__caopi_win_audio"
}

Fk:loadTranslationTable{
  ['$os_mou__caopi_win_audio'] = '昔始皇一统六国，朕平吴蜀何尝不可？',
}

moucaopiwin:addEffect('active', {})

return moucaopiwin
  ```

