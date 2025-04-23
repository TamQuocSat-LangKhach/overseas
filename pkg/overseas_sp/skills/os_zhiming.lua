local osZhiming = fk.CreateSkill {
  name = "os__zhiming"
}

Fk:loadTranslationTable{
  ["os__zhiming"] = "知命",
  [":os__zhiming"] = "准备阶段开始时或弃牌阶段结束时，你摸一张牌，然后你可将一张牌置于牌堆顶。",

  ["#os__zhiming-ask"] = "知命：你可将一张牌置于牌堆顶",

  ["$os__zhiming1"] = "天定人命，仅可一窥。",
  ["$os__zhiming2"] = "知命而行，尽诸人事。",
}

local osZhimingOnUse = function(self, event, target, player)
  ---@type string
  local skillName = osZhiming.name
  local room = player.room
  player:drawCards(1, skillName)
  if player:isNude() then
    return false
  end

  local cids = room:askToCards(
    player,
    {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = skillName,
      prompt = "#os__zhiming-ask",
    }
  )
  if #cids > 0 then
    room:moveCardTo(cids, Card.DrawPile, nil, fk.ReasonPut, skillName, nil, false, player)
  end
end

osZhiming:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osZhiming.name) and player.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = osZhimingOnUse,
})

osZhiming:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osZhiming.name) and player.phase == Player.Discard
  end,
  on_cost = Util.TrueFunc,
  on_use = osZhimingOnUse,
})

return osZhiming
