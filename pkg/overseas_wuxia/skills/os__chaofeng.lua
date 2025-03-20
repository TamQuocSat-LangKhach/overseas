local os__chaofeng = fk.CreateSkill {
  name = "os__chaofeng"
}

Fk:loadTranslationTable{
  ['os__chaofeng'] = '朝凤',
  ['#os__chaofeng-prompt'] = '朝凤：你可将【杀】当【闪】、【闪】当任意【杀】使用或打出',
  ['#os__chaofeng_pd'] = '朝凤',
  ['#os__chaofeng-ask'] = '朝凤：你可与至多三名角色共同拼点，赢的角色视为对没赢的角色使用火【杀】',
  [':os__chaofeng'] = '①你可将【杀】当【闪】、【闪】当任意【杀】使用或打出。②出牌阶段开始时，你可与至多三名角色共同拼点：赢的角色视为对所有没赢的角色使用一张火【杀】。<br/><font color=>#"<b>共同拼点</b>"<br/>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。',
  ['$os__chaofeng1'] = '枪出惊百鸟，技现震诸雄。',
  ['$os__chaofeng2'] = '出如鸾凤高翱，收若百鸟归林。',
}

os__chaofeng:addEffect('viewas', {
  pattern = "slash,jink",
  card_num = 1,
  prompt = "#os__chaofeng-prompt",
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and player:canUse(c)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and (card.trueName == "slash" or card.name == "jink") and ((Fk.currentResponsePattern == nil and player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not player:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice or #cards ~= 1 then return end
    local c = Fk:cloneCard(choice)
    c:addSubcards(cards)
    c.skillName = os__chaofeng.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:canUse(Fk:cloneCard("slash"))
  end,
  enabled_at_response = function(self, player)
    return Fk.currentResponsePattern and table.find({"slash", "jink"}, function(name)
      return Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name))
    end)
  end,
})

os__chaofeng:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__chaofeng) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = table.map(
      table.filter(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local targets = player.room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 3,
      prompt = "#os__chaofeng-ask",
      skill_name = os__chaofeng.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__chaofeng", "offensive")
    player:broadcastSkillInvoke("os__chaofeng")
    local targets = table.map(event:getCostData(self), Util.Id2PlayerMapper)
    local pd = U.jointPindian(player, targets, os__chaofeng.name)
    if pd.winner then
      table.insert(targets, player)
      table.removeOne(targets, pd.winner)
      room:useVirtualCard("fire__slash", nil, pd.winner, targets, os__chaofeng.name, true)
    end
  end,
})

return os__chaofeng
