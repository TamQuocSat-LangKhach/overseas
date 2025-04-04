local os__fengqi = fk.CreateSkill {
  name = "os__fengqi"
}

Fk:loadTranslationTable{
  ['os__fengqi'] = '丰祈',
  ['@os__fengqi'] = '丰祈',
  ['#os__fengqi-ask'] = '丰祈：你可弃置一张黑色手牌，点击“确定”后选择一名角色并施法：其摸2X张牌',
  ['#os__fengqi-target'] = '丰祈：选择一名角色，点击“确定”后施法：其摸2X张牌',
  ['#os__fengqi-conjure'] = '丰祈：施法：摸2X张牌',
  ['#os__fengqi_conjure'] = '丰祈',
  [':os__fengqi'] = '出牌阶段结束时，你可弃置一张黑色手牌，选择一名角色并施法：其摸2X张牌。',
}

os__fengqi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__fengqi.name) and player.phase == Player.Play and not player:isNude() and player:getMark("@os__fengqi") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cids = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      pattern = ".|.|spade,club",
      prompt = "#os__fengqi-ask",
      skip = true,
    })
    if #cids > 0 then
      local target = room:askToChoosePlayers(player, {
        targets = table.map(room.alive_players, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os__fengqi-target",
        skill_name = os__fengqi.name,
        cancelable = false,
      })
      event:setCostData(self, {cids, target[1]})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self)[1], os__fengqi.name, player)
    local num = room:askToChoice(player, {
      choices = {"1", "2", "3"},
      skill_name = os__fengqi.name,
      prompt = "#os__fengqi-conjure",
    })
    local target = event:getCostData(self)[2]
    room:setPlayerMark(player, "@os__fengqi", {room:getPlayerById(target).general, num .. "-" .. num})
    room:setPlayerMark(player, "_os__fengqi", target)
  end,
})

os__fengqi:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__fengqi") ~= 0 and string.sub(player:getMark("@os__fengqi")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengqi")[2], "-")
    local num = tonumber(nums[1])
    local target = room:getPlayerById(player:getMark("_os__fengqi"))
    room:notifySkillInvoked(player, "os__fengqi")
    player:broadcastSkillInvoke("os__fengqi")
    target:drawCards(2 * num, os__fengqi.name)
    room:setPlayerMark(player, "@os__fengqi", 0)
    room:setPlayerMark(player, "_os__fengqi", 0)
  end,
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__fengqi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengqi")[2], "-")
    room:setPlayerMark(player, "@os__fengqi", {player:getMark("@os__fengqi")[1], nums[1] .. "-" .. tonumber(nums[2]) - 1})
  end,
})

return os__fengqi
