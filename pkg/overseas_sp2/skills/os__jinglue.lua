local os__jinglue = fk.CreateSkill {
  name = "os__jinglue"
}

Fk:loadTranslationTable{
  ['os__jinglue'] = '景略',
  ['#os__jinglue_do'] = '景略',
  [':os__jinglue'] = '出牌阶段限一次，若场上没有“死士”牌，你可观看一名其他角色的手牌，将其中一张牌标记为“死士”。当“死士”牌被其使用时，你令此牌无效；其回合结束时，若“死士”牌在牌堆、弃牌堆或任意角色的区域内，你获得之。',
  ['$os__jinglue1'] = '安待良机，自有舍身报吾之士。',
  ['$os__jinglue2'] = '察局备间，保诸事不虞。',
}

-- 主动技能
os__jinglue:addEffect('active', {
  name = "os__jinglue",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(os__jinglue.name, Player.HistoryPhase) < 1 and table.every(Fk:currentRoom().alive_players, function(p)
      return table.every(p:getCardIds("ej"), function(id)
        return Fk:getCardById(id):getMark("_os__sishi") == 0
      end)
    end)
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected < 1 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cid = room:askToChooseCard(player, {
      target = target,
      flag = { "$Hand", target:getCardIds(Player.Hand) },
      skill_name = os__jinglue.name
    })
    room:setCardMark(Fk:getCardById(cid), "_os__sishi", {target.id, player.id})
    local mark_name = "_os__jinglue_now-" .. tostring(player.id)
    room:addTableMarkIfNeed(target, mark_name, cid)
    room:addTableMarkIfNeed(player, "_os__jinglue", target.id)
  end,
})

-- 触发技能
os__jinglue:addEffect(fk.CardUsing + fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local mark
    if event == fk.CardUsing then
      for _, id in ipairs(data.card:isVirtual() and data.card.subcards or {data.card.id}) do
        if Fk:getCardById(id):getMark("_os__sishi") ~= 0 then
          if not mark then
            mark = Fk:getCardById(id):getMark("_os__sishi")
          elseif mark ~= Fk:getCardById(id):getMark("_os__sishi") then
            return false
          end
        else
          return false
        end
      end
      return mark and mark[1] == player.id and mark[2] == data.from
    elseif player:getMark("_os__jinglue_now-" .. tostring(data.from)) ~= 0 and not Fk:currentRoom():getPlayerById(data.from).dead then
      for _, id in ipairs(player:getMark("_os__jinglue_now-" .. tostring(data.from))) do
        if table.contains({Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}, player.room:getCardArea(id)) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, room, effect)
    local player = room:getPlayerById(effect.to)
    local data_from = Fk:currentRoom():getPlayerById(effect.from)
    if event == fk.CardUsing then
      room:doIndicate(data_from.id, {player.id})
      effect.data.tos = {}
      room:sendLog{ type = "#CardNullifiedBySkill", from = player.id, arg = os__jinglue.name, arg2 = effect.data.card:toLogString() }
    else
      local cards = {}
      local mark = player:getMark("_os__jinglue_now-" .. tostring(data_from.id))
      for i = #mark, 1, -1 do
        local id = mark[i]
        if table.contains({Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}, room:getCardArea(id)) then
          table.remove(mark, i)
          room:setCardMark(Fk:getCardById(id), "_os__sishi", 0)
          table.insert(cards, id)
        end
      end
      player:setMark("_os__jinglue_now-" .. tostring(data_from.id), mark)
      data_from:obtainCard(cards, true, fk.ReasonPrey)
    end
  end,
})

return os__jinglue
