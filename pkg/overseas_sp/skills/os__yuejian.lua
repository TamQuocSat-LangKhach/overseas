local os__yuejian = fk.CreateSkill {
  name = "os__yuejian"
}

Fk:loadTranslationTable{
  ['os__yuejian'] = '约俭',
  ['os__yuejianPut'] = '约俭：置于牌堆顶或牌堆底',
  [':os__yuejian'] = '出牌阶段限一次，你可以将X张牌置于牌堆顶或牌堆底（X为你手牌数减去手牌上限的差且至少为1），若因此失去的牌数不小于：1，你的手牌上限+1；2，你回复1点体力；3，你增加1点体力上限。',
  ['$os__yuejian1'] = '吾母仪天下，于节俭处当率先垂范。',
  ['$os__yuejian2'] = '取上为贪，取下为伪，妾则取其中者。',
}

os__yuejian:addEffect('active', {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(os__yuejian.name, Player.HistoryPhase) < 1 and player:getHandcardNum() > player:getMaxCards()
  end,
  card_num = function(player)
    return player:getHandcardNum() - player:getMaxCards()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getHandcardNum() - player:getMaxCards()
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local num = #effect.cards
    room:moveCardTo(effect.cards, Card.DrawPile, nil, fk.ReasonPut, os__yuejian.name, nil, false)
    room:askToGuanxing(player, {
      cards = room:getNCards(num),
      skill_name = "os__yuejianPut",
      skip = true,
    })
    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile) --手动……
    if num > 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards)
    end
    if num > 1 then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = os__yuejian.name,
      })
    end
    if num > 2 then
      room:changeMaxHp(player, 1)
    end
  end,
})

return os__yuejian
