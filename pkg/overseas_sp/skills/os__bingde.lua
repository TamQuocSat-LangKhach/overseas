local os__bingde = fk.CreateSkill {
  name = "os__bingde"
}

Fk:loadTranslationTable{
  ['os__bingde'] = '秉德',
  ['@os__bingde-phase'] = '秉德',
  [':os__bingde'] = '出牌阶段限一次，你可弃置一张牌并选择一种花色，然后摸X张牌（X为你此阶段使用此花色的牌数），若你弃置的牌的花色和选择的花色相同，此技能视为未发动过且此阶段不能再选择相同的花色。',
  ['$os__bingde1'] = '秉德纯懿，志行忠方。',
  ['$os__bingde2'] = '慎所与，节所偏，德毕迩矣。',
}

os__bingde:addEffect('active', {
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(os__bingde.name, Player.HistoryPhase) < 1 and (player:getMark("_os__bingde_done-phase") == 0 or #player:getTableMark("_os__bingde_done-phase") < 4)
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1
  end,
  target_num = 0,
  interaction = function(self, player)
    local all = player:getTableMark("_os__bingde_done-phase")
    local all_choices = {"log_spade", "log_club", "log_heart", "log_diamond"}
    return UI.ComboBox { choices = table.filter(all_choices, function(s)
      return not table.contains(all, s)
    end), all_choices = all_choices }
  end,
  on_use = function(self, player, room, effect)
    local suit_log = self.interaction.data
    if not suit_log then return false end
    local card_suits_reverse_table = {
      log_spade = 1,
      log_club = 2,
      log_heart = 3,
      log_diamond = 4,
    }
    local suit = card_suits_reverse_table[suit_log]
    room:askToDiscard(player, {min_num = 1, max_num = 1, skill_name = os__bingde.name})
    player:drawCards(player:getMark("_os__bingde_" .. suit .. "-phase"), os__bingde.name)
    if Fk:getCardById(effect.cards[1]).suit == suit then
      player:addSkillUseHistory(os__bingde.name, -1)
      room:addTableMark(player, "_os__bingde_done-phase", suit_log)
      room:setPlayerMark(player, "_os__bingde_" .. suit .. "-phase", "x")
      room:setPlayerMark(player, "@os__bingde-phase", string.format("%s-%s-%s-%s",
        player:getMark("_os__bingde_1-phase"),
        player:getMark("_os__bingde_2-phase"),
        player:getMark("_os__bingde_3-phase"),
        player:getMark("_os__bingde_4-phase")))
    end
  end,
})

os__bingde:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__bingde) and player.phase == Player.Play and data.card.suit ~= Card.NoSuit and player:getMark("_os__bingde_" .. data.card.suit .. "-phase") ~= "x"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "_os__bingde_" .. data.card.suit .. "-phase")
    room:setPlayerMark(player, "@os__bingde-phase", string.format("%s-%s-%s-%s",
      player:getMark("_os__bingde_1-phase"),
      player:getMark("_os__bingde_2-phase"),
      player:getMark("_os__bingde_3-phase"),
      player:getMark("_os__bingde_4-phase")))
  end,
})

return os__bingde
