local os__qinghan = fk.CreateSkill {
  name = "os__qinghan"
}

Fk:loadTranslationTable{
  ['os__qinghan'] = '擎汉',
  ['#os__qinghan-active'] = '你可发动 擅汉，选择一张装备牌与一名角色拼点',
  ['#os__qinghan-trick'] = '擅汉：你可视为对%dest使用一张以其为唯一目标的普通锦囊牌',
  ['#os__qinghan_pindian'] = '擅汉',
  [':os__qinghan'] = '①出牌阶段限一次，你可用一张装备牌与一名角色拼点：若你赢，你可视为对其使用一张以其为唯一目标的普通锦囊牌；若两张拼点牌颜色相同，你与其获得对方的拼点牌。②你的拼点牌点数+X（X为你装备区牌数的两倍）。',
  ['$os__qinghan1'] = '二十四代终未竟，今以一隅誓还天！',
  ['$os__qinghan2'] = '维继丞相遗托，当负擅汉之重。',
}

os__qinghan:addEffect('active', {
  anim_type = "control",
  can_use = function (self, player)
    return player:usedSkillTimes(os__qinghan.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_num = 1,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_num = 1,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected_cards == 1 and player:canPindian(Fk:currentRoom():getPlayerById(to_select), true)
  end,
  on_use = function (self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pd = player:pindian({target}, os__qinghan.name, Fk:getCardById(effect.cards[1]))
    if pd.results[target.id].winner == player then
      local all_names = U.getAllCardNames("t")
      for i = #all_names, 1, -1 do
        local card = Fk:cloneCard(all_names[i])
        card.skillName = os__qinghan.name
        if not player:canUseTo(card, target, { bypass_times = true, bypass_distances = true }) then
          table.remove(all_names, i)
        end
      end
      local names = U.getViewAsCardNames(player, os__qinghan.name, all_names, nil)
      if #names > 0 then
        local _names = room:askToChoices(player, {
          choices = names,
          min_num = 1,
          max_num = 1,
          skill_name = os__qinghan.name,
          prompt = "#os__qinghan-trick::" .. target.id,
          all_choices = all_names,
        })
        if #_names > 0 then
          room:useVirtualCard(_names[1], nil, player, target, os__qinghan.name)
        end
      end
    end
    if pd.results[target.id].toCard:compareColorWith(pd.fromCard) then
      local moveInfos = {}
      if room:getCardArea(pd.results[target.id].toCard) == Card.DiscardPile then
        table.insert(moveInfos, {
          to = player.id,
          ids = Card:getIdList(pd.results[target.id].toCard),
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = os__qinghan.name,
        })
      end
      if room:getCardArea(pd.fromCard) == Card.DiscardPile then
        table.insert(moveInfos, {
          to = target.id,
          ids = Card:getIdList(pd.fromCard),
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = os__qinghan.name,
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    end
  end,
})

os__qinghan:addEffect(fk.PindianCardsDisplayed, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(os__qinghan) and (player == data.from or data.results[player.id]) and #player:getCardIds(Player.Equip) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:changePindianNumber(data, player, 2 * #player:getCardIds(Player.Equip), os__qinghan.name)
  end,
})

return os__qinghan
