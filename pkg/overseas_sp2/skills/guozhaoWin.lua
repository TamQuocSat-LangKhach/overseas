local os__guozhao_win_audio = fk.CreateSkill {
  name = "os__guozhao_win_audio"
}

Fk:loadTranslationTable{
  ['$os__guozhao_win_audio'] = '哼，如此蠢物，哪是本宫的对手。',
}

os__guozhao_win_audio:addEffect('active', {})

return os__guozhao_win_audio
