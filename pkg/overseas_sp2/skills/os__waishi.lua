local os__waishi = fk.CreateSkill {
  name = "os__waishi"
}

Fk:loadTranslationTable{
  ['os__waishi'] = '外使',
  ['@os__waishi_times'] = '外使次数+',
  ['#os__waishi-prompt'] = '外使：选择一名其他角色，用你选择的手牌交换其等量手牌',
  [':os__waishi'] = '出牌阶段限一次，你可选择至多X张牌（X为现存势力数），并选择一名其他角色的等量手牌，你与其交换这些牌，然后若其与你势力相同，或其手牌多于你，你摸一张牌。',
  ['$os__waishi1'] = '贵国的繁荣，在下都看到了。',
  ['$os__waishi2'] = '希望我们两国，可以世代修好。',
}

os__waishi:addEffect('active', {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(os__waishi.name, Player.HistoryPhase) < player:getMark("@os__waishi_times") + 1
  end,
  card_filter = function(self, player, to_select, selected)
    local kingdoms = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    return #selected < #kingdoms
  end,
  min_card_num = 1,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):getHandcardNum() >= #selected_cards
      and #selected_cards > 0
  end,
  target_num = 1,
  prompt = "#os__waishi-prompt",
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #effect.cards
    local cids = room:askToChooseCards(player, {
      min = n,
      max = n,
      target = target,
      flag = "h",
      skill_name = os__waishi.name
    })
    U.swapCards(room, player, player, target, effect.cards, cids, os__waishi.name)
    if not player.dead and (target.kingdom == player.kingdom or target:getHandcardNum() > player:getHandcardNum()) then
      player:drawCards(1, os__waishi.name)
    end
  end,
})

return os__waishi
