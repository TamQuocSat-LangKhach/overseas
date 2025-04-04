local os__zhouhu = fk.CreateSkill {
  name = "os__zhouhu"
}

Fk:loadTranslationTable{
  ['os__zhouhu'] = '咒护',
  ['@os__zhouhu'] = '咒护',
  ['#os__zhouhu-ask'] = '咒护：你可弃置一张红色手牌，点击“确定”后选择一名角色并施法：令其回复X点体力',
  ['#os__zhouhu-target'] = '咒护：选择一名角色，点击“确定”后施法：令其回复X点体力',
  ['#os__zhouhu-conjure'] = '咒护：施法：令其回复X点体力',
  ['#os__zhouhu_conjure'] = '咒护',
  [':os__zhouhu'] = '出牌阶段结束时，你可弃置一张红色手牌，选择一名角色并施法：令其回复X点体力。',
}

os__zhouhu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__zhouhu.name) and player.phase == Player.Play and not player:isNude() and player:getMark("@os__zhouhu") == 0
  end,
  on_cost = function(self, event, target, player, data) 
    local room = player.room
    local cids = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      pattern = ".|.|heart,diamond",
      prompt = "#os__zhouhu-ask",
      skip = true
    })
    if #cids > 0 then
      local target = room:askToChoosePlayers(player, {
        targets = table.map(room.alive_players, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os__zhouhu-target",
        skill_name = os__zhouhu.name
      })
      event:setCostData(self, {cids, target[1]})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self)[1], os__zhouhu.name, player)
    local num = room:askToChoice(player, {
      choices = {"1", "2", "3"},
      skill_name = os__zhouhu.name,
      prompt = "#os__zhouhu-conjure"
    })
    local target = event:getCostData(self)[2]
    room:setPlayerMark(player, "@os__zhouhu", {room:getPlayerById(target).general, num .. "-" .. num})
    room:setPlayerMark(player, "_os__zhouhu", target)
  end,
})

os__zhouhu:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zhouhu") ~= 0 and string.sub(player:getMark("@os__zhouhu")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouhu")[2], "-")
    local num = tonumber(nums[1])
    local target = room:getPlayerById(player:getMark("_os__zhouhu"))
    room:notifySkillInvoked(player, "os__zhouhu")
    player:broadcastSkillInvoke("os__zhouhu")
    if target:isWounded() then 
      room:recover({ who = target, num = num, recoverBy = player, skillName = os__zhouhu.name})
    end
    room:setPlayerMark(player, "@os__zhouhu", 0)
    room:setPlayerMark(player, "_os__zhouhu", 0)
  end,
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__zhouhu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouhu")[2], "-")
    room:setPlayerMark(player, "@os__zhouhu", {player:getMark("@os__zhouhu")[1], nums[1] .. "-" .. tonumber(nums[2]) - 1})
  end,
})

return os__zhouhu
