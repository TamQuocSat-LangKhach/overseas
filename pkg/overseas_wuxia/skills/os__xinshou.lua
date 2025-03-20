local os__xinshou = fk.CreateSkill {
  name = "os__xinshou"
}

Fk:loadTranslationTable{
  ['os__xinshou'] = '心授',
  ['os__dengjian'] = '登剑',
  ['#os__xinshou-invoke2'] = '你可发动〖心授〗，令〖登剑〗失效并选择一名其他角色，其视为拥有〖登剑〗直到你的下回合开始',
  ['os__xinshou_give'] = '交给一名其他角色一张牌',
  ['#os__xinshou-invoke1'] = '你可发动〖心授〗，选择一项本回合未执行过的效果',
  ['@os__xinshou_target'] = '心授',
  ['#os__xinshou-give'] = '心授：交给一名其他角色一张牌',
  ['#os__xinshou_detach'] = '心授',
  [':os__xinshou'] = '当你于出牌阶段内使用【杀】时，若此【杀】颜色与你本回合使用过的【杀】颜色均不同，你可选择一项本回合未执行过的效果：1.摸一张牌；2.交给一名其他角色一张牌。当你使用【杀】时，若你本回合执行过〖心授〗的所有效果，你可令〖登剑〗失效并选择一名其他角色，其视为拥有〖登剑〗直到你的下回合开始。若其拥有〖登剑〗时使用【杀】造成过伤害，则你的下回合开始时，你的〖登剑〗生效。',
  ['$os__xinshou1'] = '传汝于心，授汝以要！',
  ['$os__xinshou2'] = '公子少怀大志，可承吾剑！',
}

os__xinshou:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(os__xinshou.name) or data.card.trueName ~= "slash" then return end
    local record = player:getTableMark("_os__xinshou_choice-turn")
    if #record == 2 then
      return player:hasSkill("os__dengjian")
    elseif player.phase == Player.Play then
      if #record == 1 and record[1] == "draw1" and player:isNude() then return end
      local room = player.room
      local current_event_id = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true).id
      local use
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        use = e.data[1]
        if use.from == player.id and use.card.trueName == "slash" then
          return data.card:compareColorWith(use.card) and e.id ~= current_event_id
        end
        return false
      end, Player.HistoryTurn) == 0 then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local record = player:getTableMark("_os__xinshou_choice-turn")
    if #record == 2 then
      local to = player.room:askToChoosePlayers(player, {
        targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        skill_name = os__xinshou.name,
        prompt = "#os__xinshou-invoke2",
      })
      if #to > 0 then
        event:setCostData(self, to[1].id)
        return true
      end
    else
      local all_choices = {"draw1", "os__xinshou_give", "Cancel"}
      local choices = table.clone(all_choices)
      table.forEach(record, function(c) table.removeOne(choices, c) end)
      if player:isNude() then table.removeOne(choices, "os__xinshou_give") end
      local choice = player.room:askToChoice(player, {
        choices = choices,
        skill_name = os__xinshou.name,
        prompt = "#os__xinshou-invoke1",
        all_choices = all_choices,
      })
      if choice ~= "Cancel" then
        event:setCostData(self, choice)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local record = player:getTableMark("_os__xinshou_choice-turn")
    if #record == 2 then
      local to = room:getPlayerById(event:getCostData(self))
      room:setPlayerMark(player, "_os__xinshou_target", to.id)
      room:setPlayerMark(player, "@os__xinshou_target", to.general)
      room:invalidateSkill(player, "os__dengjian")
      room:handleAddLoseSkills(to, "os__dengjian", nil)
    else
      local choice = event:getCostData(self)
      table.insert(record, choice)
      room:setPlayerMark(player, "_os__xinshou_choice-turn", record)
      if choice == "draw1" then
        room:drawCards(player, 1)
      else
        local plist, card = player.room:askToChooseCardsAndPlayers(target, {
          min_card_num = 1,
          max_card_num = 1,
          targets = table.map(room:getOtherPlayers(target), Util.IdMapper),
          skill_name = os__xinshou.name,
          prompt = "#os__xinshou-give",
        })
        room:moveCardTo(card[1], Player.Hand, room:getPlayerById(plist[1].id), fk.ReasonGive, os__xinshou.name, nil, false)
      end
    end
  end,
})

os__xinshou:addEffect(fk.TurnStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("_os__xinshou_target") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("_os__xinshou_target"))
    if player:getMark("_os__xinshou_validate") ~= 0 then
      room:validateSkill(player, "os__dengjian")
      room:setPlayerMark(player, "_os__xinshou_validate", 0)
    end
    room:setPlayerMark(player, "_os__xinshou_target", 0)
    room:setPlayerMark(player, "@os__xinshou_target", 0)
    room:handleAddLoseSkills(to, "-os__dengjian", nil)
  end,
})

return os__xinshou
