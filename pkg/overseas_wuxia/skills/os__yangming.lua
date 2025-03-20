local os__yangming = fk.CreateSkill {
  name = "os__yangming"
}

Fk:loadTranslationTable{
  ['os__yangming'] = '扬名',
  ['@os__yangming-phase'] = '扬名',
  [':os__yangming'] = '出牌阶段结束时，你可摸X张牌，且此回合手牌上限+X（X为你此阶段使用牌的类别数）。',
  ['$os__yangming1'] = '善名高布凌霄阙，仁德始铸黄金台！',
  ['$os__yangming2'] = '失千金之利，得万人之心！',
}

os__yangming:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__yangming) and player.phase == Player.Play and player:getMark("@os__yangming-phase") ~= 0
  end,
  on_use = function(self, event, target, player)
    local num = #player:getMark("@os__yangming-phase")
    player:drawCards(num, os__yangming.name)
    player.room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, num)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and
      player:hasSkill(os__yang__ming, true) and player.phase == Player.Play and
      (type(player:getMark("@os__yangming-phase")) ~= "table" or
      not table.contains(player:getMark("@os__yangming-phase"), data.card:getTypeString() .. "_char"))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local typesRecorded = player:getTableMark("@os__yangming-phase")
    table.insert(typesRecorded, data.card:getTypeString() .. "_char")
    room:setPlayerMark(player, "@os__yangming-phase", typesRecorded)
  end,
})

return os__yangming
