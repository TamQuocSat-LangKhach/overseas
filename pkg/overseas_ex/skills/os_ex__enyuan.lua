local os_ex__enyuan = fk.CreateSkill {
  name = "os_ex__enyuan"
}

Fk:loadTranslationTable{
  ['os_ex__enyuan'] = '恩怨',
  ['os_ex__enyuan_draw'] = '摸一张牌',
  ['os_ex__enyuan_recover'] = '回复1点体力',
  ['#os_ex__enyuan-ask'] = '恩怨：选择一项，令%src执行',
  ['#os_ex__enyuan-give'] = '恩怨：你需交给 %src 一张手牌，否则失去1点体力',
  [':os_ex__enyuan'] = '当你获得一名其他角色至少两张牌后，你可令其摸一张牌；若其手牌区或装备区没有牌，你可改为令其回复1点体力。当你受到1点伤害后，你令伤害来源交给你一张手牌，否则失去1点体力；若其交给你的牌不是<font color=>♥</font>，则你摸一张牌。',
  ['$os_ex__enyuan1'] = '报之以李，还之以桃。',
  ['$os_ex__enyuan2'] = '伤了我，休想全身而退！',
}

os_ex__enyuan:addEffect(fk.AfterCardsMove, {
  mute = true,
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os_ex__enyuan.name) then return false end
    for _, move in ipairs(data) do
      if move.from ~= nil and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = os_ex__enyuan.name })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os_ex__enyuan.name, 1)
    room:notifySkillInvoked(player, os_ex__enyuan.name, "support")
    local targetPlayer
    for _, move in ipairs(data) do
      if move.from ~= nil and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
        targetPlayer = room:getPlayerById(move.from)
        break
      end
    end
    if (#targetPlayer.player_cards[Player.Hand] == 0 or #targetPlayer.player_cards[Player.Equip] == 0) and targetPlayer:isWounded() then
      local choice = room:askToChoice(player, { choices = {"os_ex__enyuan_draw", "os_ex__enyuan_recover"}, skill_name = os_ex__enyuan.name, prompt = "#os_ex__enyuan-ask:" .. targetPlayer.id })
      if choice == "os_ex__enyuan_recover" then
        room:recover({ who = targetPlayer, num = 1, recoverBy = player, skillName = os_ex__enyuan.name})
      else
        targetPlayer:drawCards(1, os_ex__enyuan.name)
      end
    else
      targetPlayer:drawCards(1, os_ex__enyuan.name)
    end
  end,
})

os_ex__enyuan:addEffect(fk.Damaged, {
  mute = true,
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.from and data.from ~= player and not data.from.dead and not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self:doCost(event, target, player, data) then break end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os_ex__enyuan.name, 2)
    room:notifySkillInvoked(player, os_ex__enyuan.name)
    local cids = room:askToCards(data.from, { min_num = 1, max_num = 1, include_equip = false, pattern = ".|.|.|hand|.|.", prompt = "#os_ex__enyuan-give:"..player.id })
    if #cids > 0 then
      room:moveCardTo(cids, Player.Hand, player, fk.ReasonGive, os_ex__enyuan.name, nil, false)
      if Fk:getCardById(cids[1]).suit ~= Card.Heart then
        player:drawCards(1, os_ex__enyuan.name)
      end
    else
      room:loseHp(data.from, 1, os_ex__enyuan.name)
    end
  end,
})

return os_ex__enyuan
