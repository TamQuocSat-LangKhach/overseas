local moonSpearSkill = fk.CreateSkill {
  name = "#moon_spear_skill"
}

Fk:loadTranslationTable{
  ['#moon_spear_skill'] = '银月枪',
  ['moon_spear'] = '银月枪',
  ['#moon_spear_skill-ask'] = '银月枪：你可使用【杀】',
}

moonSpearSkill:addEffect(fk.AfterCardsMove, {
  attached_equip = "moon_spear",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(moonSpearSkill) or player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") ~= 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseCard(player, {
      skill_name = "#moon_spear_skill-ask",
      pattern = "slash",
      cancelable = true
    })
    if use then
      event:setCostData(skill, use)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
    room:useCard(event:getCostData(skill))
  end,

  can_refresh = function(self, event, target, player, data)
    if player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") > 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_moon_spear-turn")
  end,
})

return moonSpearSkill
