local ifcaoangwin = fk.CreateSkill {
  name = "os_if__caoang_win_audio"
}

Fk:loadTranslationTable{
  ['$os_if__caoang_win_audio'] = '拂晓之光，终慰吾灵。',
}

ifcaoangwin:addEffect('active', {})

return ifcaoangwin
