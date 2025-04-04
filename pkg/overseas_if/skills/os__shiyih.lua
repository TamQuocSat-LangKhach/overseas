local os__shiyih = fk.CreateSkill {
  name = "os__shiyih"
}

Fk:loadTranslationTable{
  ['os__shiyih'] = '拾忆',
  ['#os__shiyih-active'] = '拾忆：你可与一名其他角色互相观看手牌，然后各展示自己的一张手牌',
  [':os__shiyih'] = '出牌阶段限一次，你可与一名其他角色互相观看手牌，各展示自己的一张手牌，并从牌堆或弃牌堆中获得一张与此牌类型相同的牌。若你与其展示的牌：类型相同，你与其摸两张牌；类型不同，你与其从牌堆或弃牌堆中获得一张与展示的牌类型相同的牌。',
}

os__shiyih:addEffect('active', {
  anim_type = "support",
  prompt = "#os__shiyih-active",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player, card, extra_data)
    return player:usedSkillTimes(os__shiyih.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function (self, room, effect, event)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    local targets = {player, target}
    local poxi = Fk.poxi_methods["os__shiyih"]

    for _, p in ipairs(targets) do
      local other, card_data, extra_data = table.unpack(os__shiyihGetPoxiData(p, player, target, os__shiyih.name))

      local result = room:askToPoxi(p, {
        poxi_type = "os__shiyih",
        data = card_data,
        extra_data = extra_data,
        cancelable = false
      })

      local log = {
        type = "#WatchCard",
        from = p.id,
        card = other:getCardIds(Player.Hand),
      }
      p:doNotify("GameLog", json.encode(log))

      if result == "" then
        ret[p.id] = poxi.default_choice(card_data, extra_data)
      else
        ret[p.id] = poxi.post_select(result, card_data, extra_data)
      end
    end

    player:showCards(ret[player.id])
    if not target.dead then target:showCards(ret[target.id]) end
    os__shiyihObtain(room, targets, ret, player, os__shiyih.name)
    if Fk:getCardById(ret[target.id][1]).type == Fk:getCardById(ret[player.id][1]).type then
      for _, p in ipairs(targets) do
        if not p.dead then p:drawCards(2, os__shiyih.name) end
      end
    else
      os__shiyihObtain(room, targets, ret, player, os__shiyih.name)
    end
  end
})

return os__shiyih
