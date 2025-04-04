local ifhuancaoangwin = fk.CreateSkill {
  name = "os_if_huan__caoang_win_audio"
}

Fk:loadTranslationTable{
  ['$os_if_huan__caoang_win_audio'] = '煌煌大魏，万世长明！',
}

ifhuancaoangwin:addEffect('active', {})

return ifhuancaoangwin
