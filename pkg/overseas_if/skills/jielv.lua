local jielv = fk.CreateSkill {
  name = "os__jielv",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__jielv"] = "竭虑",
  [":os__jielv"] = "锁定技，一名角色的回合结束时，若你于本回合内未对其使用过牌，则你失去1点体力；当你受到1点伤害或失去1点体力后，" ..
  "若你的体力上限小于7，则你加1点体力上限。",

  ["$os__jielv1"] = "竭一国之材，尽万人之力！",
  ["$os__jielv2"] = "穷力尽心，亮定以血补天！",
}

jielv:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jielv.name) and
    #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      return use.from == player and table.contains(use.tos, target)
    end, Player.HistoryTurn) == 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, jielv.name)
  end,
})

local spec = {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jielv.name) and player.maxHp < 7
  end,
  on_use = function (self, event, target, player, data)
    player.room:changeMaxHp(player, 1)
  end,
}

jielv:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = spec.can_trigger,
  on_use = spec.on_use,
})

jielv:addEffect(fk.HpLost, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.num
  end,
  can_trigger = spec.can_trigger,
  on_use = spec.on_use,
})

return jielv
