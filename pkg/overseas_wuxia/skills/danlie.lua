local danlie = fk.CreateSkill {
  name = "os__danlie"
}

Fk:loadTranslationTable{
  ['os__danlie'] = '胆烈',
  ['#danlie_pd'] = '胆烈',
  [':os__danlie'] = '出牌阶段限一次，你可以与至多三名角色共同拼点，若你：赢，你对没赢的角色造成1点伤害；没赢，你失去1点体力。你的拼点牌点数+X（X为你已损失的体力值）。<br/><font color=>#"<b>共同拼点</b>"<br/>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。',
  ['$os__danlie1'] = '师者如父，辱师之仇亦如辱父！',
  ['$os__danlie2'] = '壮士自怀豪烈胆，初生幼虎敢搏龙！',
}

danlie:addEffect('active', {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(danlie.name, Player.HistoryPhase) == 0
  end,
  min_target_num = 1,
  max_target_num = 3,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= player.id and player:canPindian(target) and #selected < 3
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    -- local pd = player:pindian(table.map(targets, Util.Id2PlayerMapper), self.name)
    local pd = U.jointPindian(player, targets, danlie.name)
    if pd.winner == player then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = danlie.name,
          }
        end
      end
    elseif not player.dead then
      room:loseHp(player, 1, danlie.name)
    end
  end,
})

danlie:addEffect(fk.PindianCardsDisplayed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(danlie) and (data.from == player or table.contains(data.tos, player)) and player:isWounded()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, danlie.name)
    player:broadcastSkillInvoke(danlie.name)
    room:changePindianNumber(data, player, player:getLostHp(), danlie.name)
  end,
})

return danlie
