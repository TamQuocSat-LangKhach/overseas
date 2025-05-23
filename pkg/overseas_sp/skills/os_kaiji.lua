local osKaiji = fk.CreateSkill {
  name = "os__kaiji"
}

Fk:loadTranslationTable{
  ["os__kaiji"] = "开济",
  [":os__kaiji"] = "准备阶段开始时，你可令至多X名角色各摸一张牌，若有角色以此法获得了非基本牌，你摸一张牌（X为本局游戏进入过濒死状态的角色数+1）。",

  ["#os__kaiji-ask"] = "开济：你可令至多 %arg 名角色各摸一张牌",

  ["$os__kaiji1"] = "力除秦汉之弊，方可治化复兴。",
  ["$os__kaiji2"] = "约官实录，勿与百姓争利。",
}

osKaiji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osKaiji.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
      table.insertIfNeed(targets, e.data.who)
    end, Player.HistoryGame)
    local num = 1 + #targets
    local tos = room:askToChoosePlayers(
      player,
        {
        targets = room:getAlivePlayers(false),
        min_num = 1,
        max_num = num,
        prompt = "#os__kaiji-ask:::" .. num,
        skill_name = osKaiji.name,
      }
    )
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osKaiji.name

    local invoke = false
    local tos = event:getCostData(self).tos
    for _, p in ipairs(tos) do
      if p:isAlive() then
        local cid = p:drawCards(1, skillName)[1]
        if not invoke and Fk:getCardById(cid).type ~= Card.TypeBasic then
          invoke = true
        end
      end
    end
    if invoke and player:isAlive() then
      player:drawCards(1, skillName)
    end
  end,
})

return osKaiji
