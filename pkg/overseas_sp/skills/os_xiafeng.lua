local osXiafeng = fk.CreateSkill {
  name = "os__xiafeng"
}

Fk:loadTranslationTable{
  ["os__xiafeng"] = "黠凤",
  [":os__xiafeng"] = "出牌阶段开始时，你可消耗至多3点<a href='os__baonue_href'>暴虐值</a>，" ..
  "令你本回合接下来使用的X张牌无距离和次数限制且不可被响应，手牌上限+X。（X为消耗暴虐值）",

  ["#os__xiafeng"] = "黠凤：本回合接下来使用的前X张牌无距离和次数限制且不能被响应，手牌上限+X",
  ["#os__xiafeng_log"] = "%from 消耗了 %arg 点暴虐值",
  ["@os__xiafeng-turn"] = "黠凤 剩余",

  ["$os__xiafeng1"] = "穷奇凶戾，黠凤诡诈。",
  ["$os__xiafeng2"] = "鸾凤襄蛟，黠风殷狰。",
}

-- 主技能效果
osXiafeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osXiafeng.name) and player.phase == Player.Play and player:getMark("@os__baonue") > 0
  end,
  on_cost = function(self, event, target, player)
    local choices = {}
    for i = 1, math.min(3, player:getMark("@os__baonue")) do
      table.insert(choices, tostring(i))
    end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osXiafeng.name,
        prompt = "#os__xiafeng",
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local num = tonumber(event:getCostData(self))
    local room = player.room
    room:addPlayerMark(player, "@os__xiafeng-turn", num)
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, num)
    room:removePlayerMark(player, "@os__baonue", num)
    room:sendLog{
      type = "#os__xiafeng_log",
      from = player.id,
      arg = num,
    }
  end,
})

osXiafeng:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@os__xiafeng-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@os__xiafeng-turn")
    data.extra_data = data.extra_data or {}
    data.extra_data.osXiafengBuff = true
  end,
})

-- 不可响应效果
osXiafeng:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).osXiafengBuff
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
  end,
})

-- 目标修正效果
osXiafeng:addEffect("targetmod", {
  bypass_times = function(self, player, skill2, scope, card, to)
    return card and player:getMark("@os__xiafeng-turn") > 0 and scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill2, card)
    return card and player:getMark("@os__xiafeng-turn") > 0
  end,
})

osXiafeng:addAcquireEffect(function(self, player)
  for _, effect in ipairs(Fk.skills["#os__baonue_mark"]:getSkeleton().effects) do
    player.room.logic:addTriggerSkill(effect)
  end
end)

return osXiafeng
