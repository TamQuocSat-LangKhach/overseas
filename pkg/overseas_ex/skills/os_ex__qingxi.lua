local os_ex__qingxi = fk.CreateSkill {
  name = "os_ex__qingxi"
}

Fk:loadTranslationTable{
  ['os_ex__qingxi'] = '倾袭',
  ['#os_ex__qingxi'] = '你想对 %dest 发动技能“倾袭”吗？',
  ['os_ex__qingxi_draw'] = '令%arg摸%arg2张牌，你不可响应此【杀】',
  ['os_ex__qingxi_discard'] = '弃置装备区里的所有牌并弃置等量其装备区的牌（不足则全弃），此【杀】伤害+1',
  [':os_ex__qingxi'] = '当你使用【杀】指定目标后，若此【杀】为此回合你使用的第一张【杀】，你可令目标角色选择一项：1.令你摸X张牌，此【杀】不可被响应（X为你装备牌的数量且至少为1）；2. 弃置装备区里的所有牌（至少一张）并弃置等量你装备区的牌（不足则全弃），此【杀】伤害+1。',
  ['$os_ex__qingxi1'] = '此残兵败将，胜之若儿戏耳！',
  ['$os_ex__qingxi2'] = '有休在此，主公何虑？哈哈哈哈！',
}

os_ex__qingxi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(os_ex__qingxi.name) or data.card.trueName ~= "slash" then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      return use.from == player.id and use.card.trueName == "slash"
    end, Player.HistoryTurn)
    return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id --就是UseCard
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = os_ex__qingxi.name,
      prompt = "#os_ex__qingxi::" .. data.to
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local num = #player:getCardIds(Player.Equip)
    local choices = {"os_ex__qingxi_draw:::" .. player.general .. ":" .. tostring(math.max(1, num)), "os_ex__qingxi_discard"}
    local all_choices = table.clone(choices)
    local num2 = #to:getCardIds(Player.Equip)
    if num2 == 0 then table.remove(choices, 2) end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = os_ex__qingxi.name,
      all_choices = all_choices
    })
    if choice == "os_ex__qingxi_discard" then
      to:throwAllCards("e")
      if #player:getCardIds(Player.Equip) > 0 and to:isAlive() then
        num = math.min(num, num2)
        local cards = room:askToChooseCards(to, {
          min_num = num,
          max_num = num,
          target = player,
          flag = "e",
          skill_name = os_ex__qingxi.name
        })
        room:throwCard(cards, os_ex__qingxi.name, player, to)
      end
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      player:drawCards(math.max(1, num), os_ex__qingxi.name)
      data.disresponsive = true
    end
  end,
})

return os_ex__qingxi
