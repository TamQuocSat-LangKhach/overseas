local os__zhanyi = fk.CreateSkill {
  name = "os__zhanyi"
}

Fk:loadTranslationTable{
  ['os__zhanyi'] = '战意',
  ['#os__zhanyi-prompt'] = '战意:弃置一张牌并失去1点体力，根据弃置牌的种类获得效果',
  ['@os__zhanyi-phase'] = '战意',
  ['os__zhanyi_basic&'] = '战意',
  ['#os__zhanyi_buff'] = '战意',
  ['#os__zhanyi-get'] = '战意：获得%dest弃置的一张牌',
  [':os__zhanyi'] = '出牌阶段限一次，你可弃置一张牌并失去1点体力，根据牌的种类获得以下效果直到出牌阶段结束，基本牌：你可将一张基本牌当成任意基本牌使用，你使用的第一张基本牌的伤害值或回复值基数+1；锦囊牌：你摸三张牌，你使用的锦囊牌不能被抵消；装备牌：当你使用【杀】指定一名角色为目标后，其弃置两张牌，你选择其中一张获得之。<br /><font color=>（注：【酒】不享受伤害值+1效果）</font>',
  ['$os__zhanyi1'] = '以战养战，视敌而战。',
  ['$os__zhanyi2'] = '战，可以破敌。意，可以守御。',
}

os__zhanyi:addEffect('active', {
  anim_type = "drawcard",
  prompt = "#os__zhanyi-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(os__zhanyi.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cardType = Fk:getCardById(effect.cards[1]):getTypeString()
    room:throwCard(effect.cards, os__zhanyi.name, player, player)
    if player.dead then return end
    room:loseHp(player, 1, os__zhanyi.name)
    if player.dead then return end
    room:setPlayerMark(player, "@os__zhanyi-phase", cardType)
    if cardType == "basic" then
      room:handleAddLoseSkills(player, "os__zhanyi_basic&", nil, false, true)
      room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        room:handleAddLoseSkills(player, "-os__zhanyi_basic&", nil, false, true)
      end)
    elseif cardType == "trick" then
      player:drawCards(3, os__zhanyi.name)
    end
  end,
})

os__zhanyi:addEffect('trigger', {
  anim_type = "offensive",
  events = {fk.CardUsing, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or player:getMark("@os__zhanyi-phase") == 0 then return false end
    if event == fk.CardUsing then
      if player:getMark("@os__zhanyi-phase") == "basic" then
        return data.card.type == Card.TypeBasic and player:getMark("_os__zhanyi_additional-phase") == 0
      elseif player:getMark("@os__zhanyi-phase") == "trick" then
        return data.card.type == Card.TypeTrick
      end
    else
      return data.card.trueName == "slash" and player:getMark("@os__zhanyi-phase") == "equip"
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      if player:getMark("@os__zhanyi-phase") == "basic" then
        data.additionalDamage = (data.additionalDamage or 0) + 1
        data.additionalRecover = (data.additionalRecover or 0) + 1
        room:addPlayerMark(player, "_os__zhanyi_additional-phase")
      else
        data.unoffsetableList = table.map(player.room.alive_players, Util.IdMapper)
      end
    else
      local to = room:getPlayerById(data.to)
      local cids = room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = os__zhanyi.name,
        cancelable = false,
        pattern = ".",
      })
      cids = table.filter(cids, function(id) return room:getCardArea(id) == Card.DiscardPile end)
      if #cids > 0 then
        local cards = room:askToChooseCard(player, {
          target = to,
          flag = { card_data = { { "pile_discard", cids } } },
          skill_name = os__zhanyi.name,
        })
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, "os__zhanyi", nil, true)
      end
    end
  end,
})

return os__zhanyi
