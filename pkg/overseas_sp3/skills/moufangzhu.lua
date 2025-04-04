local moufangzhu = fk.CreateSkill {
  name = "os_mou__fangzhu"
}

Fk:loadTranslationTable{
  ['os_mou__fangzhu'] = '放逐',
  ['#os_mou__fangzhu'] = '放逐：你可选择一名角色，消耗一定数量的“颂”标记对其进行限制',
  ['os_mou__fangzhu_only_basic'] = '1枚：只可使用基本牌',
  ['os_mou__fangzhu_only_trick'] = '2枚：只可使用锦囊牌',
  ['os_mou__fangzhu_only_equip'] = '3枚：只可使用装备牌',
  ['os_mou__fangzhu_nullify_skill'] = '2枚：武将技能失效',
  ['os_mou__fangzhu_disresponsable'] = '2枚：不可响应他人牌',
  ['os_mou__fangzhu_turn_over'] = '3枚：翻面',
  ['@os_mou__xingshang_song'] = '颂',
  ['@os_mou__fangzhu_limit'] = '放逐限',
  ['@@os_mou__fangzhu_skill_nullified'] = '放逐 技能失效',
  ['@@os_mou__fangzhu_disresponsable'] = '放逐 不可响应',
  ['#os_mou__fangzhu_prohibit'] = '放逐',
  [':os_mou__fangzhu'] = '出牌阶段限一次，若你有“行殇”，则你可以选择一名其他角色，并移去至少一枚“颂”标记令其执行对应操作：1枚，直到其下个回合结束，其不能使用基本牌外的手牌；2枚，直到其下个回合结束，其所有技能失效或其不可响应除其外的角色使用的牌，或其不能使用锦囊牌外的手牌；3枚，其翻面或直到其下个回合结束，其不能使用装备牌外的手牌（若为斗地主，则令其他角色技能失效、只可使用装备牌及翻面的效果不可选择）。',
  ['$os_mou__fangzhu1'] = '朕于天下无所不容，而况汝乎？',
  ['$os_mou__fangzhu2'] = '世子之争素来如此，朕予改封已是仁慈！',
}

moufangzhu:addEffect('active', {
  anim_type = "control",
  prompt = "#os_mou__fangzhu",
  card_num = 0,
  target_num = 1,
  interaction = function(skill)
    local choiceList = {
      "os_mou__fangzhu_only_basic",
      "os_mou__fangzhu_only_trick",
      "os_mou__fangzhu_only_equip",
      "os_mou__fangzhu_nullify_skill",
      "os_mou__fangzhu_disresponsable",
      "os_mou__fangzhu_turn_over",
    }
    local choices = {}
    for i = 1, math.min(skill.player:getMark("@os_mou__xingshang_song"), 3) do
      if i == 1 then
        table.insert(choices, "os_mou__fangzhu_only_basic")
      elseif i == 2 then
        table.insert(choices, "os_mou__fangzhu_only_trick")
        if not Fk:currentRoom():isGameMode("1v2_mode") then
          table.insert(choices, "os_mou__fangzhu_nullify_skill")
        end
        table.insert(choices, "os_mou__fangzhu_disresponsable")
      else
        if not Fk:currentRoom():isGameMode("1v2_mode") then
          table.insertTable(choices, { "os_mou__fangzhu_only_equip", "os_mou__fangzhu_turn_over" })
        end
      end
    end
    return UI.ComboBox { choices = choices, all_choices = choiceList }
  end,
  can_use = function(self, player)
    return
      player:usedSkillTimes(moufangzhu.name, Player.HistoryPhase) == 0 and
      player:getMark("@os_mou__xingshang_song") > 0 and
      player:hasSkill(mouxingshang, true)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= skill.player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    local choice = skill.interaction.data
    if choice:startsWith("os_mou__fangzhu_only") then
      choice = choice:sub(-5)
      room:removePlayerMark(player, "@os_mou__xingshang_song", choice == "basic" and 1 or (choice == "trick" and 2 or 3))
      local limit_mark = target:getTableMark("@os_mou__fangzhu_limit")
      table.insertIfNeed(limit_mark, choice.."_char")
      room:setPlayerMark(target, "@os_mou__fangzhu_limit", limit_mark)
    elseif choice == "os_mou__fangzhu_nullify_skill" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      room:setPlayerMark(target, "@@os_mou__fangzhu_skill_nullified", 1)
    elseif choice == "os_mou__fangzhu_disresponsable" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      room:setPlayerMark(target, "@@os_mou__fangzhu_disresponsable", 1)
    elseif choice == "os_mou__fangzhu_turn_over" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 3)
      target:turnOver()
    end
  end,
})

moufangzhu:addEffect(fk.AfterTurnEnd, {
  can_refresh = function(self, event, player)
    return table.find(
      { "@os_mou__fangzhu_limit", "@@os_mou__fangzhu_skill_nullified", "@@os_mou__fangzhu_disresponsable" },
      function(markName) return player:getMark(markName) ~= 0 end
    )
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room

    for _, markName in ipairs({ "@os_mou__fangzhu_limit", "@@os_mou__fangzhu_skill_nullified", "@@os_mou__fangzhu_disresponsable" }) do
      if player:getMark(markName) ~= 0 then
        room:setPlayerMark(player, markName, 0)
      end
    end
  end,
})

moufangzhu:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player)
    return table.find(
      player.room.alive_players,
      function(p) return p:getMark("@@os_mou__fangzhu_disresponsable") > 0 and p ~= target end
    )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room

    data.disresponsiveList = data.disresponsiveList or {}
    local tos = table.filter(
      player.room.alive_players,
      function(p) return p:getMark("@@os_mou__fangzhu_disresponsable") > 0 and p ~= target end
    )
    table.insertTableIfNeed(data.disresponsiveList, table.map(tos, Util.IdMapper))
  end,
})

moufangzhu:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    local typeLimited = player:getMark("@os_mou__fangzhu_limit")
    if typeLimited == 0 then return false end
    if table.every(Card:getIdList(card), function(id)
      return table.contains(player:getCardIds(Player.Hand), id)
    end) then
      return #typeLimited > 1 or typeLimited[1] ~= card:getTypeString() .. "_char"
    end
  end,
})

moufangzhu:addEffect('invalidity', {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@os_mou__fangzhu_skill_nullified") > 0 and skill:isPlayerSkill(from)
  end
})

return moufangzhu
