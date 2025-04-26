local moonSpearSkill = fk.CreateSkill {
  name = "#moon_spear_skill",
  attached_equip = "moon_spear",
}

Fk:loadTranslationTable{
  ["#moon_spear_skill"] = "银月枪",
  ["#moon_spear_skill-ask"] = "银月枪：你可使用【杀】",
  [":#moon_spear_skill"] = "当你于其他角色的回合中首次失去牌后，你可使用【杀】。",
}

moonSpearSkill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(moonSpearSkill.name) or player.room.current == player
      or player:getMark("_moon_spear-turn") ~= 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_moon_spear-turn") -- …
    local use = player.room:askToUseCard(player, {
      skill_name = "#moon_spear_skill-ask",
      pattern = "slash",
      cancelable = true
    })
    if use then
      event:setCostData(self, {use = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
    room:useCard(event:getCostData(self).use)
  end,
})

return moonSpearSkill
