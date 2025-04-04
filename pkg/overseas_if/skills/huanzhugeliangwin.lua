local huanzhugeliangwin = fk.CreateSkill {
  name = "os_if_huan__zhugeliang_win_audio"
}

Fk:loadTranslationTable{
  ['$os_if_huan__zhugeliang_win_audio'] = '卧龙腾于九天，炎汉之火长明。',
}

huanzhugeliangwin:addEffect('active', {})

return huanzhugeliangwin
