local os__xiawei = fk.CreateSkill {
  name = "os__xiawei"
}

Fk:loadTranslationTable{
  ['os__xiawei'] = '狭威',
  ['os__pomp&'] = '威',
  ['os__xiawei_ask'] = '将牌堆顶的%arg张牌作为“威”',
  ['#os__xiawei-invoke'] = '狭威：你可将牌堆顶若干张牌置于你的武将牌上，称为“威”；你可将“威”如手牌般使用或打出',
  ['@os__xiawei_presume-turn'] = '狭威妄行',
  ['#os__xiawei_presume'] = '狭威',
  ['#os__xiawei_presume-discard'] = '狭威：弃置 %arg 张牌，否则减1点体力上限',
  [':os__xiawei'] = '游戏开始时，你将牌堆中两张基本牌置于你的武将牌上，称为“威”；你可将“威”如手牌般使用或打出；回合开始时，你将所有“威”置入弃牌堆。<a href=>妄行</a>：准备阶段，你可将牌堆顶的X+1张牌置于你的武将牌上，称为“威”。',
  ['$os__xiawei1'] = '既闻仲帝威名，还不速速归降！',
  ['$os__xiawei2'] = '仲朝国土，岂容贼军放肆！'
}

os__xiawei:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cids = room:getCardsFromPileByRule(".|.|.|.|.|basic", 2)
    if #cids > 0 then
      player:addToPile("os__pomp&", cids, true, skill.name)
      player:setMark("_os__pomp", cids)
    end
  end,
})

os__xiawei:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player)
    return target == player and #player:getPile("os__pomp&") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:setMark("_os__pomp", 0)
    room:moveCardTo(player:getPile("os__pomp&"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, "os__pomp&")
  end,
})

os__xiawei:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local ret = "os__xiawei_ask:::"
    local choices = {}
    for i = 2, 5 do
      table.insert(choices, ret .. i)
    end
    table.insert(choices, "Cancel")
    local num = player.room:askToChoice(player, {
      choices = choices,
      skill_name = skill.name,
      prompt = "#os__xiawei-invoke"
    })
    if num ~= "Cancel" then
      event:setCostData(skill, table.indexOf(choices, num))
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local num = event:getCostData(skill)
    local cids = room:getNCards(num + 1)
    room:setPlayerMark(player, "@os__xiawei_presume-turn", num)
    if #cids > 0 then
      player:addToPile("os__pomp&", cids, true, skill.name)
      player:setMark("_os__pomp", cids)
    end
  end,
})

local os__xiawei_presume = fk.CreateTriggerSkill{
  name = "#os__xiawei_presume",
  events = {fk.EventPhaseStart},
  anim_type = "negative",
}

os__xiawei:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return player == target and player.phase == Player.Finish and player:getMark("@os__xiawei_presume-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local num = player:getMark("@os__xiawei_presume-turn")
    if #room:askToDiscard(player, {
      min_num = num,
      max_num = num,
      include_equip = true,
      skill_name = skill.name,
      cancelable = true,
      pattern = ".",
      prompt = "#os__xiawei_presume-discard:::" .. num
    }) == 0 then
      room:changeMaxHp(player, -1)
    end
  end,
})

return os__xiawei
