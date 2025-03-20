local shenyi = fk.CreateSkill {
  name = "os__shenyi"
}

Fk:loadTranslationTable{
  ['os__shenyi'] = '伸义',
  ['os__chivalry'] = '侠义',
  ['@$os__shenyi'] = '伸义',
  ['#os__shenyi-ask_own'] = '伸义：你可选择一种基本牌或锦囊牌的牌名（每种限一次）',
  ['#os__shenyi-ask_other'] = '伸义：你可选择一种基本牌或锦囊牌的牌名（每种限一次），然后可将任意张手牌交给 %dest',
  ['#os__shenyi-give'] = '伸义：你可将任意张手牌交给 %dest',
  ['@@os__shenyi'] = '伸义',
  ['#os__shenyi_delay'] = '伸义',
  [':os__shenyi'] = '每回合限一次，当你或你攻击范围内的角色此回合首次受到其他角色造成的伤害后，你可选择一种基本牌或锦囊牌的牌名（每种限一次），然后将牌堆中一张此牌名的牌置于你的武将牌上（没有则改为该类别的一张牌），称为“侠义”，然后你可以将任意张手牌交给其，当其失去一张你以此法交给其的牌时，你摸一张牌。',
  ['$os__shenyi1'] = '施仁德于天下，伸大义于四海！',
  ['$os__shenyi2'] = '汉道虽衰，亦不容汝等奸祟放肆！',
}

shenyi:addEffect(fk.Damaged, {
  derived_piles = "os__chivalry",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(shenyi.name) and (player:inMyAttackRange(target) or player == target) and
      player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].to == target and e.data[1].from and e.data[1].from ~= player end)[1].data[1] == data and
      player:usedSkillTimes(shenyi.name) == 0) then return false end
    local all_names = U.getAllCardNames("bdt")
    return #player:getTableMark("@$os__shenyi") < #all_names
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shenyi.name,
      prompt = target == player and "#os__shenyi-ask_own" or "#os__shenyi-ask_other::" .. target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_names = U.getAllCardNames("bdt")
    local record = player:getTableMark("@$os__shenyi")
    local choices = table.filter(all_names, function(name) return not table.contains(record, name) end)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = shenyi.name,
      prompt = "#os__shenyi-choose",
      all_choices = all_names
    })
    table.insert(record, choice)
    room:setPlayerMark(player, "@$os__shenyi", record)
    local card = room:getCardsFromPileByRule(choice)
    if #card == 0 then
      card = room:getCardsFromPileByRule(".|.|.|.|.|" .. Fk:cloneCard(choice):getTypeString())
    end
    if #card > 0 then
      player:addToPile("os__chivalry", card[1], true, shenyi.name)
    end
    if target ~= player and not target.dead and not player:isKongcheng() then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = player:getHandcardNum(),
        skill_name = shenyi.name,
        prompt = "#os__shenyi-give::" .. target.id
      })
      if #cards == 0 then return end
      room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, shenyi.name, nil, false, player.id)
      for _, id in ipairs(cards) do
        if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == target then
          room:setCardMark(Fk:getCardById(id), "@@os__shenyi", player.id)
        end
      end
    end
  end,
  on_lose = function (self, player, is_death)
    player.room:setPlayerMark(player, "@$os__shenyi", 0)
    UsableSkill.onLose(self, player, is_death)
  end
})

shenyi:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local cards = {}
    for _, move in ipairs(data) do
      local from = player.room:getPlayerById(move.from)
      if from and (move.to ~= from.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@os__shenyi") == player.id then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, cid in ipairs(event:getCostData(self)) do
      room:setCardMark(Fk:getCardById(cid), "@@os__shenyi", 0)
    end
    if player.dead then return end
    player:broadcastSkillInvoke(shenyi.name)
    room:notifySkillInvoked(player, shenyi.name, "drawcard")
    player:drawCards(#event:getCostData(self), shenyi.name)
  end,
})

return shenyi
