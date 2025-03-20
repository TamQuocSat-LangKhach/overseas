local os__zhiming = fk.CreateSkill {
  name = "os__zhiming"
}

Fk:loadTranslationTable{
  ['os__zhiming'] = '知命',
  ['#os__zhiming-ask'] = '知命：你可将一张牌置于牌堆顶',
  [':os__zhiming'] = '准备阶段开始时或弃牌阶段结束时，你摸一张牌，然后你可将一张牌置于牌堆顶。',
  ['$os__zhiming1'] = '天定人命，仅可一窥。',
  ['$os__zhiming2'] = '知命而行，尽诸人事。',
}

os__zhiming:addEffect({fk.EventPhaseStart, fk.EventPhaseEnd}, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__zhiming.name) and
      ((event == fk.EventPhaseStart and player.phase == Player.Start) or (event == fk.EventPhaseEnd and player.phase == Player.Discard))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(1, os__zhiming.name)
    if player:isNude() then return false end
    local cids = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__zhiming.name,
      cancelable = true,
      prompt = "#os__zhiming-ask",
    })
    if #cids > 0 then
      room:moveCardTo(cids, Card.DrawPile, nil, fk.ReasonPut, os__zhiming.name, nil, false)
    end
  end,
})

return os__zhiming
