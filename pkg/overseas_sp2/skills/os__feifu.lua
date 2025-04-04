local os__feifu = fk.CreateSkill {
  name = "os__feifu"
}

Fk:loadTranslationTable{
  ['os__feifu'] = '非服',
  ['#os__feifu-give'] = '非服：请交给 %src 一张牌',
  ['#os__feifu-use'] = '非服：你可使用%arg',
  [':os__feifu'] = '锁定技，转换技，阳：当你使用【杀】指定唯一目标后；阴：当你成为【杀】的唯一目标后；目标角色A须交给此【杀】的使用者B一张牌，若此牌为装备牌，B可使用此牌。',
  ['$os__feifu1'] = '此亦久矣，其能复几！',
  ['$os__feifu2'] = '君既赌输，理当再脱一件。',
  ['$os__feifu3'] = '以侯归第？终败于其！',
  ['$os__feifu4'] = '君若如此，让我如何见人？'
}

os__feifu:addEffect(fk.TargetSpecified, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(os__feifu.name) then return false end
    return data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 and ((event == fk.TargetSpecified and player:getSwitchSkillState(os__feifu.name) == 0) or (event == fk.TargetConfirmed and player:getSwitchSkillState(os__feifu.name) == 1)) and not player.room:getPlayerById(data.to):isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__feifu.name, "switch")
    if event == fk.TargetSpecified then
      player:broadcastSkillInvoke(os__feifu.name, math.random(1, 2))
    else
      player:broadcastSkillInvoke(os__feifu.name, math.random(3, 4))
    end
    local user = room:getPlayerById(data.from)
    local target = room:getPlayerById(data.to)
    room:doIndicate(player.id, {player == user and data.to or data.from})
    local cids = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__feifu.name,
      cancelable = false,
      prompt = "#os__feifu-give:" .. data.from
    })
    if #cids > 0 then
      room:moveCardTo(cids, Player.Hand, user, fk.ReasonGive, os__feifu.name, nil, false)
      local card = Fk:getCardById(cids[1])
      if card.type == Card.TypeEquip and room:getCardOwner(card) == user and room:getCardArea(card) == Card.PlayerHand then
        local cardName = card.name
        local use = room:askToUseRealCard(user, {
          pattern = cardName .. "|.|.|.|.|." .. cids[1],
          skill_name = os__feifu.name,
          prompt = "#os__feifu-use:::" .. card:toLogString(),
          cancelable = true
        })
        if use then room:useCard(use) end
      end
    end
  end,
})

return os__feifu
