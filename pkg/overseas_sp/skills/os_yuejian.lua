local osYuejian = fk.CreateSkill {
  name = "os__yuejian"
}

Fk:loadTranslationTable{
  ["os__yuejian"] = "约俭",
  [":os__yuejian"] = "出牌阶段限一次，你可以将X张牌置于牌堆顶或牌堆底（X为你手牌数减去手牌上限的差且至少为1），" ..
  "若因此失去的牌数不小于：1，你的手牌上限+1；2，你回复1点体力；3，你增加1点体力上限。",

  ["os__yuejianPut"] = "约俭：置于牌堆顶或牌堆底",

  ["$os__yuejian1"] = "吾母仪天下，于节俭处当率先垂范。",
  ["$os__yuejian2"] = "取上为贪，取下为伪，妾则取其中者。",
}

osYuejian:addEffect("active", {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(osYuejian.name, Player.HistoryPhase) < 1 and player:getHandcardNum() > player:getMaxCards()
  end,
  card_num = function(self, player)
    return player:getHandcardNum() - player:getMaxCards()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getHandcardNum() - player:getMaxCards()
  end,
  target_num = 0,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osYuejian.name
    local player = effect.from
    local num = #effect.cards

    local result = room:askToGuanxing(
      player,
      {
        cards = effect.cards,
        skill_name = "os__yuejianPut",
        skip = true,
      }
    )
    local moveList = {}
    if #result.top > 0 then
      table.insert(moveList, {
        ids = table.reverse(result.top),
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = skillName,
        proposer = player,
      })
    end
    if #result.bottom > 0 then
      table.insert(moveList, {
        ids = result.bottom,
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = skillName,
        proposer = player,
        drawPilePosition = -1,
      })
    end
    room:moveCards(table.unpack(moveList))

    if num > 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards)
    end
    if num > 1 then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
    end
    if num > 2 then
      room:changeMaxHp(player, 1)
    end
  end,
})

return osYuejian
