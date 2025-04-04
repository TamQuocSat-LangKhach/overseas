local os__suizheng = fk.CreateSkill {
  name = "os__suizheng"
}

Fk:loadTranslationTable{
  ['os__suizheng'] = '随征',
  ['#os__suizheng-ask'] = '随征：选择一名其他角色，作为“随征”角色',
  ['@os__suizheng'] = '随征',
  ['#os__suizheng-discard'] = '随征：你可弃置两张基本牌，令 %dest 回复1点体力；或点“取消”，失去1点体力，令其从牌堆或弃牌堆中获得一张【杀】或【决斗】',
  [':os__suizheng'] = '锁定技，游戏开始时，你选择一名其他角色。当其造成伤害后，你摸一张牌；当其受到伤害后，你须选择一项：1. 失去1点体力，令其从牌堆或弃牌堆中获得一张【杀】或【决斗】；2. 弃置两张基本牌，令其回复1点体力。',
  ['$os__suizheng1'] = '续得将军器重，愿随将军出征！',
  ['$os__suizheng2'] = '吾与将军有亲，哼！尔等岂可与我相比！',
  ['$os__suizheng3'] = '将军莫慌，万事有吾！',
}

os__suizheng:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return not player:hasSkill(os__suizheng.name) or false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__suizheng.name, 1)
    room:notifySkillInvoked(player, os__suizheng.name, "support")
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__suizheng-ask",
      skill_name = os__suizheng.name,
      cancelable = false
    })
    if #tos > 0 then
      local to = room:getPlayerById(tos[1].id)
      room:setPlayerMark(player, "_os__suizheng", to.id)
      room:setPlayerMark(player, "@os__suizheng", to.general)
    end
  end,
})

os__suizheng:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player)
    return player:getMark("_os__suizheng") == target.id and not player.dead
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__suizheng.name, 2)
    room:notifySkillInvoked(player, os__suizheng.name, "drawcard")
    player:drawCards(1, os__suizheng.name)
  end,
})

os__suizheng:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player)
    return player:getMark("_os__suizheng") == target.id and not player.dead
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__suizheng.name, 3)
    room:notifySkillInvoked(player, os__suizheng.name, "support")
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = os__suizheng.name,
      cancelable = player.hp > 0,
      pattern = ".|.|.|.|.|basic",
      prompt = "#os__suizheng-discard::" .. target.id
    })
    if #cards == 2 then
      if not target.dead then
        room:recover({ who = target, num = 1, recoverBy = player, skillName = os__suizheng.name})
      end
    else
      room:loseHp(player, 1, os__suizheng.name)
      if not target.dead then
        local cids = room:getCardsFromPileByRule("slash,duel", 1, "allPiles")
        if #cids > 0 then
          room:obtainCard(target, cids[1], false, fk.ReasonPrey)
        end
      end
    end
  end,
})

return os__suizheng
