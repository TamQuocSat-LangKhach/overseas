local os__fujian = fk.CreateSkill {
  name = "os__fujian"
}

Fk:loadTranslationTable{
  ['os__fujian'] = '负剑',
  [':os__fujian'] = '锁定技，①游戏开始时或准备阶段开始时，若你的装备区里没有武器牌，则你从牌堆中随机获得一张武器牌并将其置入装备区。②当你于回合外失去武器牌后，你失去1点体力。',
  ['$os__fujian1'] = '得此宝剑，如虎添翼！',
  ['$os__fujian2'] = '丞相至宝，汝岂配用之？啊！……',
}

os__fujian:addEffect({fk.GameStart, fk.EventPhaseStart}, {
  global = false,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(skill.name) then return false end
    if (event == fk.GameStart or (player == target and target.phase == Player.Start)) and not player:getEquipment(Card.SubtypeWeapon) then
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, skill.name, "drawcard")
    player:broadcastSkillInvoke(skill.name, 1)
    local id = room:getCardsFromPileByRule(".|.|.|.|.|weapon")
    if #id > 0 then
      room:obtainCard(player, id[1], false, fk.ReasonPrey)
      if not player:getEquipment(Card.SubtypeWeapon) then
        player.room:moveCardTo(id, Card.PlayerEquip, player, fk.ReasonJustMove, skill.name)
      end
    end
  end,
})

os__fujian:addEffect(fk.AfterCardsMove, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) then return false end
    if player.phase ~= Player.NotActive then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).sub_type == Card.SubtypeWeapon and (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, skill.name, "negative")
    player:broadcastSkillInvoke(skill.name, 2)
    room:loseHp(player, 1, skill.name)
  end,
})

return os__fujian
