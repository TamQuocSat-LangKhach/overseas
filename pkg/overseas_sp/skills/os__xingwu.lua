local os__xingwu = fk.CreateSkill {
  name = "os__xingwu"
}

Fk:loadTranslationTable{
  ['os__xingwu'] = '星舞',
  ['os__dance'] = '星舞',
  ['#os__xingwu-put'] = '星舞：你可将一张牌置于你的武将牌上（称为“星舞”）',
  ['#os__xingwu_damage'] = '星舞',
  ['#os__xingwu-damage'] = '你可将三张“星舞”置入弃牌堆，弃置一名其他角色装备区里的所有牌，对其造成2/1点伤害',
  [':os__xingwu'] = '弃牌阶段开始时，你可将一张牌置于你的武将牌上（称为“星舞”），然后你可将三张“星舞”置入弃牌堆，选择一名其他角色，弃置其装备区里的所有牌，然后若其为男/非男性角色，你对其造成2/1点伤害。',
  ['$os__xingwu1'] = '哼，不要小瞧女孩子哦！',
  ['$os__xingwu2'] = '姐妹齐心，其利断金。',
}

os__xingwu:addEffect(fk.EventPhaseStart, {
  expand_pile = "os__dance",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__xingwu) and player.phase == Player.Discard and not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local cids = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = os__xingwu.name,
      prompt = "#os__xingwu-put",
    })
    if #cids > 0 then
      event:setCostData(self, cids[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:addToPile("os__dance", event:getCostData(self), true, os__xingwu.name)
    if #player:getPile("os__dance") < 3 then return end
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "#os__xingwu_damage",
      prompt = "#os__xingwu-damage",
      cancelable = true,
    })
    if dat then
      local to = room:getPlayerById(dat.targets[1])
      room:moveCardTo(dat.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, os__xingwu.name)
      room:throwCard(to:getCardIds(Player.Equip), os__xingwu.name, to, player)
      room:damage{
        from = player,
        to = to,
        damage = to:isMale() and 2 or 1,
        skillName = os__xingwu.name,
      }
    end
  end,
})

return os__xingwu
