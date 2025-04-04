local ifzhugeliangwin = fk.CreateSkill {
  name = "os_if__zhugeliang_win_audio"
}

Fk:loadTranslationTable{
  ['$os_if__zhugeliang_win_audio'] = '卧龙腾于九天，炎汉之火长明。',
}

ifzhugeliangwin:addEffect('active', {})

return ifzhugeliangwin
