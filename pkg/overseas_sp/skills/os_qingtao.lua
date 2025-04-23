local osQingtao = fk.CreateSkill {
  name = "os__qingtao"
}

Fk:loadTranslationTable{
  ["os__qingtao"] = "清滔",
  [":os__qingtao"] = "摸牌阶段结束时，你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌。若你本回合未发动此技能，你可于此回合的结束阶段开始时发动此技能。",

  ["#os__qingtao-ask"] = "清滔：你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌",
 
  ["$os__qingtao1"] = "君子当如滔流，循道而不失其行。",
  ["$os__qingtao2"] = "探赜索隐，钩深致远。日月在躬，隐之弥曜。",
}

local osQingtaoOnCost = function(self, event, target, player)
  local ids = player.room:askToCards(
    player,
    {
      min_num = 1,
      max_num = 1,
      skill_name = osQingtao.name,
      prompt = "#os__qingtao-ask",
    }
  )
  if #ids > 0 then
    event:setCostData(self, ids)
    return true
  end
end

local osQingtaoOnUse = function(self, event, target, player)
  ---@type string
  local skillName = osQingtao.name
  local room = player.room
  room:recastCard(event:getCostData(self), player, skillName)
  if player:isAlive() then
    local card = Fk:getCardById(event:getCostData(self)[1])
    if card.name == "analeptic" or card.type ~= Card.TypeBasic then
      player:drawCards(1, skillName)
    end
  end
end

osQingtao:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osQingtao.name) and player.phase == Player.Draw
  end,
  on_cost = osQingtaoOnCost,
  on_use = osQingtaoOnUse,
})

osQingtao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osQingtao.name) and
      player.phase == Player.Discard and
      player:usedSkillTimes(osQingtao.name, Player.HistoryTurn) == 0
  end,
  on_cost = osQingtaoOnCost,
  on_use = osQingtaoOnUse,
})

return osQingtao
