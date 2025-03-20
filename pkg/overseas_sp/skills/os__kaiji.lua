local os__kaiji = fk.CreateSkill {
  name = "os__kaiji"
}

Fk:loadTranslationTable{
  ['os__kaiji'] = '开济',
  ['#os__kaiji-ask'] = '开济：你可令至多 %arg 名角色各摸一张牌',
  [':os__kaiji'] = '准备阶段开始时，你可令至多X名角色各摸一张牌，若有角色以此法获得了非基本牌，你摸一张牌（X为本局游戏进入过濒死状态的角色数+1）。',
  ['$os__kaiji1'] = '力除秦汉之弊，方可治化复兴。',
  ['$os__kaiji2'] = '约官实录，勿与百姓争利。',
}

os__kaiji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__kaiji) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
      table.insertIfNeed(targets, e.data[1].who)
    end, Player.HistoryGame)
    local num = 1 + #targets
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = num,
      prompt = "#os__kaiji-ask:::" .. num,
      skill_name = os__kaiji.name,
      cancelable = true
    })
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local invoke = false
    local cost_data = event:getCostData(self)
    for _, pid in ipairs(cost_data.tos) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        local cid = p:drawCards(1, os__kaiji.name)[1]
        if not invoke and Fk:getCardById(cid).type ~= Card.TypeBasic then
          invoke = true
        end
      end
    end
    if invoke and not player.dead then
      player:drawCards(1, os__kaiji.name)
    end
  end,
})

return os__kaiji
