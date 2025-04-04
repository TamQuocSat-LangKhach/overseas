local os__xianfeng = fk.CreateSkill {
  name = "os__xianfeng"
}

Fk:loadTranslationTable{
  ['os__xianfeng'] = '先锋',
  ['#os__xianfeng'] = '你想对 %dest 发动技能“先锋”吗？',
  ['os__xianfeng_self'] = '你摸一张牌，直到其下回合开始，其至你距离-1',
  ['os__xianfeng_yg'] = '其摸一张牌，直到其下回合开始，你至其距离-1',
  ['#os__xianfeng-ask'] = '先锋：对 %src 选择一项',
  ['@os__xianfeng'] = '先锋',
  ['@os__xianfeng_others'] = '先锋',
  [':os__xianfeng'] = '当你于出牌阶段使用伤害牌对其他角色造成伤害后，你可令其选择一项：1. 其摸一张牌，直到你的下回合开始，你至其他角色距离-1；2. 你摸一张牌，直到你的下回合开始，其至你距离-1。',
  ['$os__xianfeng1'] = '吾领万余白马，可堪此战先锋！',
  ['$os__xianfeng2'] = '白马先发，敌不攻而散！',
}

os__xianfeng:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__xianfeng.name) and player.phase == Player.Play and data.to ~= player and data.card and data.card.is_damage_card and not player.dead and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = os__xianfeng.name,
      prompt = "#os__xianfeng::" .. data.to.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = data.to
    local choice = room:askToChoice(target, {
      choices = {"os__xianfeng_self", "os__xianfeng_yg"},
      skill_name = os__xianfeng.name,
      prompt = "#os__xianfeng-ask:" .. player.id
    })
    if choice == "os__xianfeng_self" then
      target:drawCards(1, os__xianfeng.name)
      room:addPlayerMark(player, "@os__xianfeng")
    else
      player:drawCards(1, os__xianfeng.name)
      room:addTableMark(player, "_os__xianfeng_others", target.id)
      local record = type(target:getMark("@os__xianfeng_others")) == "table" and target:getMark("@os__xianfeng_others") or {player.general, 0}
      record[2] = record[2] - 1
      room:setPlayerMark(target, "@os__xianfeng_others", record)
    end
  end,
})

os__xianfeng:addEffect('distance', {
  name = "#os__xianfeng_distance",
  correct_func = function(self, from, to)
    if from:getMark("@os__xianfeng") > 0 then
      return -from:getMark("@os__xianfeng")
    end
  end,
})

os__xianfeng:addEffect('distance', {
  name = "#os__xianfeng_others_distance",
  correct_func = function(self, from, to)
    if to:getMark("_os__xianfeng_others") ~= 0 then
      return -#table.filter(to:getMark("_os__xianfeng_others"), function(pid) return from.id == pid end)
    end
  end,
})

os__xianfeng:addEffect(fk.TurnStart, {
  name = "#os__xianfeng_cleaner",
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    return player:getMark("@os__xianfeng") ~= 0 or player:getMark("_os__xianfeng_others") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__xianfeng", 0)
    room:setPlayerMark(player, "_os__xianfeng_others", 0)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@os__xianfeng_others", 0)
    end
  end,
})

os__xianfeng:addEffect(fk.Death, {
  name = "#os__xianfeng_cleaner",
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    return player:getMark("_os__xianfeng_others") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__xianfeng", 0)
    room:setPlayerMark(player, "_os__xianfeng_others", 0)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@os__xianfeng_others", 0)
    end
  end,
})

return os__xianfeng
