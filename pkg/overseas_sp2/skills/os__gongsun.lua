local os__gongsun = fk.CreateSkill {
  name = "os__gongsun"
}

Fk:loadTranslationTable{
  ['os__gongsun'] = '共损',
  ['#os__gongsun-target'] = '共损：请选择攻击范围内的一名角色',
  ['#os__gongsun-suit'] = '共损：请选择一种花色，直至你的下个回合开始前，你和 %src 无法使用、打出或弃置该花色的手牌。',
  ['@os__gongsun'] = '共损',
  [':os__gongsun'] = '锁定技，出牌阶段开始时，你选择攻击范围内的一名角色并选择一种花色，直至你的下个回合开始前，你与其无法使用、打出或弃置该花色的手牌。',
  ['$os__gongsun1'] = '我岂能与魏延这种莽夫共事！',
  ['$os__gongsun2'] = '早知如此，投靠魏国又如何！',
}

os__gongsun:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target)
    return target == self.player and self.player:hasSkill(os__gongsun.name) and self.player.phase == Player.Play
  end,
  on_cost = function(self, event, target)
    local room = self.player.room
    local availableTargets = table.map(table.filter(room:getOtherPlayers(self.player, false), function(p)
      return self.player:inMyAttackRange(p)
    end), Util.IdMapper)
    if #availableTargets == 0 then return false end
    local targetPlayer = room:askToChoosePlayers(self.player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__gongsun-target",
      skill_name = os__gongsun.name,
      cancelable = false,
    })
    if #targetPlayer > 0 then
      local choice = room:askToChoice(self.player, {
        choices = {"log_spade", "log_club", "log_heart", "log_diamond"},
        skill_name = os__gongsun.name,
        prompt = "#os__gongsun-suit:" .. targetPlayer[1].id,
      })
      event:setCostData(self, {targetPlayer[1].id, choice})
      return true
    end
    return false
  end,
  on_use = function(self, event, target)
    local room = self.player.room
    local targetPlayer = room:getPlayerById(event:getCostData(self)[1])
    room:addTableMarkIfNeed(self.player, "_os__gongsun", targetPlayer.id)
    for _, p in ipairs({self.player, targetPlayer}) do
      room:addTableMark(p, "@os__gongsun", event:getCostData(self)[2])
    end
  end,
  can_refresh = function(self, event, target)
    return target == self.player and self.player:getMark("_os__gongsun") ~= 0
  end,
  on_refresh = function(self, event, target)
    local room = self.player.room
    room:setPlayerMark(self.player, "@os__gongsun", 0)
    table.forEach(table.map(self.player:getMark("_os__gongsun"), function(pid)
      return room:getPlayerById(pid)
    end), function(p)
        room:setPlayerMark(p, "@os__gongsun", 0)
      end)
  end,
})

local os__gongsun_prohibit = fk.CreateSkill {
  name = "#os__gongsun_prohibit"
}

os__gongsun_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return type(player:getMark("@os__gongsun")) == "table" and table.contains(player:getMark("@os__gongsun"), card:getSuitString(true)) and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  prohibit_response = function(self, player, card)
    return type(player:getMark("@os__gongsun")) == "table" and table.contains(player:getMark("@os__gongsun"), card:getSuitString(true)) and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  prohibit_discard = function(self, player, card)
    return type(player:getMark("@os__gongsun")) == "table" and table.contains(player:getMark("@os__gongsun"), card:getSuitString(true)) and table.contains(player.player_cards[Player.Hand], card.id)
  end,
})

return os__gongsun
