local xinghan = fk.CreateSkill {
  name = "os__xinghan"
}

Fk:loadTranslationTable{
  ['os__xinghan'] = '兴汉',
  ['os__chivalry'] = '侠义',
  ['#os__xinghan-ask'] = '兴汉：你可依次使用“侠义”牌，然后此回合结束时，你弃置所有手牌并失去X点体力（X为你的体力值-1且至少为1）',
  ['os__xinghan_viewas'] = '兴汉',
  ['#os__xinghan-use'] = '兴汉：使用“侠义”牌 %arg',
  ['#os__xinghan_filter'] = '侠义',
  [':os__xinghan'] = '你的回合外或当你处于濒死状态时，你可如手牌般使用或打出“侠义”牌。准备阶段开始时，若“侠义”牌的数量大于存活角色数，你可依次使用“侠义”牌，然后此回合结束时，你弃置所有手牌并失去X点体力（X为你的体力值-1且至少为1）。',
  ['$os__xinghan1'] = '继先汉之荣，开万世泰平！',
  ['$os__xinghan2'] = '立此兴汉之志，终不可渝！',
}

-- TriggerSkill Effect
xinghan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xinghan.name) and player.phase == Player.Start and #player:getPile("os__chivalry") > #player.room.alive_players
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xinghan.name,
      prompt = "#os__xinghan-ask"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("os__chivalry")
    for i = #cards, 1, -1 do
      local cid = cards[i]
      if player:getPileNameOfId(cid) == "os__chivalry" and room:getCardOwner(cid) == player then
        local card = Fk:getCardById(cid)
        room:setPlayerMark(player, "os__xinghan_card", cid)
        if player:canUse(card) then
          room:delay(100)
          local success, dat = room:askToUseActiveSkill(player, {
            skill_name = "os__xinghan_viewas",
            prompt = "#os__xinghan-use:::" .. card:toLogString(),
            cancelable = true,
            extra_data = Util.DummyTable,
            no_indicate = true
          })
          room:setPlayerMark(player, "os__xinghan_card", 0)
          if success then
            room:useCard{
              from = player.id,
              tos = table.map(dat.targets, function(id) return {id} end),
              card = card,
            }
          end
        else
          room:setPlayerMark(player, "os__xinghan_card", 0)
        end
      end
    end
  end,
})

-- Delay TriggerSkill Effect
xinghan:addEffect(fk.TurnEnd, {
  name = "#os__xinghan_delay",
  anim_type = "negative",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(xinghan.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, xinghan.name, "negative")
    player:throwAllCards("h")
    if not player.dead then
      room:loseHp(player, math.max(1, player.hp - 1), xinghan.name)
    end
  end,
})

-- FilterSkill Effect
xinghan:addEffect('filter', {
  name = "#os__xinghan_filter",
  handly_cards = function(self, player)
    if player:hasSkill(xinghan.name) and (Fk:currentRoom():getCurrent() ~= player or player.dying) then
      return player:getPile("os__chivalry")
    end
  end,
})

return xinghan
