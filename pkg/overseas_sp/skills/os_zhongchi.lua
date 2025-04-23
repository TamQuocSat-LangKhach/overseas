local osZhongchi = fk.CreateSkill {
  name = "os__zhongchi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__zhongchi"] = "众斥",
  [":os__zhongchi"] = "锁定技，当累计有X名角色因〖征建〗交给你牌后（X为游戏人数的一半，向上取整），" ..
  "你本局游戏受到【杀】的伤害+1，并将〖征建〗中的“其交给你一张牌”修改为“你可对其造成1点伤害”。",

  ["$os__zhongchi1"] = "陛下，兴已知错。",
  ["$os__zhongchi2"] = "微臣有罪，任凭陛下处置。",
}

osZhongchi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osZhongchi.name) or player:usedSkillTimes(osZhongchi.name, Player.HistoryGame) > 0 then
      return false
    end

    local num = (#player.room.players + 1) // 2
    if tonumber(player:getMark("@os__zhengjian_use")) < num and tonumber(player:getMark("@os__zhengjian_obtain")) < num then
      return false
    end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        return true
      end
    end
  end,
})

osZhongchi:addEffect(fk.DamageInflicted, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:usedSkillTimes(osZhongchi.name, Player.HistoryGame) > 0 and
      event.data.card and
      event.data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return osZhongchi
