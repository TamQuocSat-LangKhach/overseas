local os__duoduan = fk.CreateSkill {
  name = "os__duoduan"
}

Fk:loadTranslationTable{
  ['os__duoduan'] = '度断',
  ['#os__duoduan-ask'] = '度断：你可重铸一张牌',
  ['#os__duoduan-discard'] = '度断：弃置一张牌令此【杀】不可被响应，否则你摸两张牌令此【杀】无效',
  [':os__duoduan'] = '每回合限一次，当你成为【杀】的目标后，你可重铸一张牌，然后你令此【杀】的使用者须弃置一张牌令此【杀】不可被响应，否则其摸两张牌令此【杀】无效。',
  ['$os__duoduan1'] = '北伐之事，丞相亦听我定夺。',
  ['$os__duoduan2'] = '筹定规画，片刻既定！',
}

os__duoduan:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__duoduan.name) and data.card.trueName == "slash" and not player:isNude() and player:usedSkillTimes(os__duoduan.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__duoduan.name,
      cancelable = true,
      prompt = "#os__duoduan-ask",
    })
    if #cids > 0 then
      event:setCostData(self, cids)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recastCard(event:getCostData(self), player, os__duoduan.name)
    local from = room:getPlayerById(data.from)
    if #room:askToDiscard(from, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__duoduan.name,
      cancelable = true,
      prompt = "#os__duoduan-discard",
    }) > 0 then
      local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard) -- AimStruct 没有 disresponsiveList
      parentUseData.data[1].disresponsiveList = parentUseData.data[1].disresponsiveList or {}
      table.forEach(room.alive_players, function(p)
        table.insertIfNeed(parentUseData.data[1].disresponsiveList, p.id)
      end)
    else
      from:drawCards(2, os__duoduan.name)
      table.forEach(room.alive_players, function(p)
        table.insertIfNeed(data.nullifiedTargets, p.id)
      end)
    end
  end,
})

return os__duoduan
