local os__zhongchi = fk.CreateSkill {
  name = "os__zhongchi"
}

Fk:loadTranslationTable{
  ['os__zhongchi'] = '众斥',
  ['@os__zhengjian_use'] = '征建使用非基',
  ['@os__zhengjian_obtain'] = '征建获得牌',
  [':os__zhongchi'] = '锁定技，当累计有X名角色因〖征建〗交给你牌后（X为游戏人数的一半，向上取整），你本局游戏受到【杀】的伤害+1，并将〖征建〗中的“其交给你一张牌”修改为“你可对其造成1点伤害”。',
  ['$os__zhongchi1'] = '陛下，兴已知错。',
  ['$os__zhongchi2'] = '微臣有罪，任凭陛下处置。',
}

os__zhongchi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__zhongchi.name) or player:usedSkillTimes(os__zhongchi.name, Player.HistoryGame) > 0 then return false end
    local num = (#player.room.players + 1) // 2
    if tonumber(player:getMark("@os__zhengjian_use")) < num and tonumber(player:getMark("@os__zhengjian_obtain")) < num then return false end
    for _, move in ipairs(event.data.moves) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      if target and move.to == player.id and move.toArea == Card.PlayerHand then
        return true
      end
    end
  end,
})

os__zhongchi:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player)
    return target == player and player:usedSkillTimes(os__zhongchi.name, Player.HistoryGame) > 0 and event.data.card and event.data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player)
    event.data.damage = event.data.damage + 1
  end,
})

return os__zhongchi
