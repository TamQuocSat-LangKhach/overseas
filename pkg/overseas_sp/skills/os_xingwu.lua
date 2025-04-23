local osXingwu = fk.CreateSkill {
  name = "os__xingwu"
}

Fk:loadTranslationTable{
  ["os__xingwu"] = "星舞",
  [":os__xingwu"] = "弃牌阶段开始时，你可将一张牌置于你的武将牌上（称为“星舞”），然后你可将三张“星舞”置入弃牌堆，" ..
  "选择一名其他角色，弃置其装备区里的所有牌，然后若其为男/非男性角色，你对其造成2/1点伤害。",

  ["os__dance"] = "星舞",
  ["#os__xingwu-put"] = "星舞：你可将一张牌置于你的武将牌上（称为“星舞”）",
  ["#os__xingwu-damage"] = "你可将三张“星舞”置入弃牌堆，弃置一名其他角色装备区里的所有牌，对其造成2/1点伤害",

  ["$os__xingwu1"] = "哼，不要小瞧女孩子哦！",
  ["$os__xingwu2"] = "姐妹齐心，其利断金。",
}

osXingwu:addEffect(fk.EventPhaseStart, {
  expand_pile = "os__dance",
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osXingwu.name) and
      player.phase == Player.Discard and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local cids = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = osXingwu.name,
        prompt = "#os__xingwu-put",
      }
    )
    if #cids > 0 then
      event:setCostData(self, cids[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osXingwu.name
    local room = player.room
    player:addToPile("os__dance", event:getCostData(self), true, skillName, player)
    if #player:getPile("os__dance") < 3 then
      return false
    end

    local plist, cids = room:askToChooseCardsAndPlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        min_card_num = 3,
        max_card_num = 3,
        targets = room:getOtherPlayers(player, false),
        pattern = ".|.|.|os__dance",
        skill_name = skillName,
        prompt = "#os__xingwu-damage",
        extra_data = { expand_pile = "os__dance" },
      }
    )
    if #plist > 0 and #cids > 0 then
      local to = plist[1]
      room:moveCardTo(cids, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, "os__dance", true, player)
      room:throwCard(to:getCardIds("e"), skillName, to, player)
      room:damage{
        from = player,
        to = to,
        damage = to:isMale() and 2 or 1,
        skillName = skillName,
      }
    end
  end,
})

return osXingwu
