local os__fengpo = fk.CreateSkill {
  name = "os__fengpo"
}

Fk:loadTranslationTable{
  ['os__fengpo'] = '凤魄',
  ['@@os__fengpo_update'] = '凤魄2级',
  ['os__fengpo_draw'] = '摸%arg张牌',
  ['os__fengpo_damage'] = '令此牌的伤害值基数+%arg',
  ['#os__fengpo-choose'] = '凤魄：观看%dest的手牌并选择',
  [':os__fengpo'] = '当你使用【杀】或【决斗】仅指定一名角色为目标后，你可观看其手牌然后选择一项：1.摸X张牌；2.令此牌的伤害值基数+X（X为其<font color=>♦</font>手牌数，若你于本局游戏内杀死过角色，则修改为“其红色手牌数”）。',
  ['$os__fengpo1'] = '看我不好好杀杀你的威风。',
  ['$os__fengpo2'] = '贼人是不是被本姑娘吓破胆了呀？'
}

os__fengpo:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__fengpo.name) and (data.card.trueName == "slash" or data.card.name == "duel")
      and U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) and not player.room:getPlayerById(data.to):isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cids = to:getCardIds(Player.Hand)

    local update = player:getMark("@@os__fengpo_update") > 0
    local n = #table.filter(cids, function(id)
      return update and Fk:getCardById(id).color == Card.Red or Fk:getCardById(id).suit == Card.Diamond
    end)

    local choice = room:askToChoice(player, {
      choices = {"os__fengpo_draw:::" .. n, "os__fengpo_damage:::" .. n},
      skill_name = os__fengpo.name,
      prompt = "#os__fengpo-choose::" .. data.to,
      view_cards = cids
    })

    if choice:startsWith("os__fengpo_draw") then
      player:drawCards(n, os__fengpo.name)
    else
      data.additionalDamage = (data.additionalDamage or 0) + n
    end
  end,
})

os__fengpo:addEffect(fk.Deathed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(os__fengpo.name) and data.damage and data.damage.from == player and player:getMark("@@os__fengpo_update") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__fengpo_update", 1)
  end,
})

os__fengpo:addEffect("acquire", {
  on_acquire = function (skill, player, is_start)
    if not is_start then
      local room = player.room
      if #room.logic:getEventsOfScope(GameEvent.Death, 1, function(e)
        local death = e.data[1]
        return death.damage and death.damage.from == player
      end, Player.HistoryGame) == 1 then
        room:setPlayerMark(player, "@@os__fengpo_update", 1)
      end
    end
  end,
})

os__fengpo:addEffect("lose", {
  on_lose = function (skill, player, is_death)
    player.room:setPlayerMark(player, "@@os__fengpo_update", 0)
  end,
})

return os__fengpo
