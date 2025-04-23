local osCuijin = fk.CreateSkill{
  name = "os__cuijin"
}

Fk:loadTranslationTable{
  ["os__cuijin"] = "催进",
  [":os__cuijin"] = "当你或攻击范围内的角色使用【杀】时，你可弃置一张牌，令此【杀】伤害值基数+1。" ..
  "当此【杀】结算结束后，若此【杀】未造成伤害，你对此【杀】的使用者造成1点伤害。",

  ["#os__cuijin-ask"] = "是否弃置一张牌，对 %dest 发动“催进”",
  ["#os__cuijin_delay"] = "催进",

  ["$os__cuijin1"] = "诸军速行，违者军法论处！",
  ["$os__cuijin2"] = "快！贻误军机者，定斩不赦！",
}

osCuijin:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osCuijin.name) and
      (target == player or player:inMyAttackRange(target)) and
      data.card.trueName == "slash" and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = osCuijin.name,
        skip = true,
        prompt = "#os__cuijin-ask::" .. target.id,
      }
    )
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, { target })
    room:throwCard(event:getCostData(self).cards, osCuijin.name, player, player)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.os__cuijinUser = data.extra_data.os__cuijinUser or {}
    table.insert(data.extra_data.os__cuijinUser, player.id)
  end,
})

osCuijin:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      table.contains((data.extra_data or {}).os__cuijinUser or {}, player.id) and
      not data.damageDealt and
      player:isAlive() and
      target:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, { target })
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = osCuijin.name,
    }
  end,
})

return osCuijin
