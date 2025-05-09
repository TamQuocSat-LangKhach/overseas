local piankuang = fk.CreateSkill {
  name = "os__piankuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__piankuang"] = "偏狂",
  [":os__piankuang"] = "锁定技，当你使用【杀】对目标角色造成伤害时，若你本回合使用【杀】造成过伤害，此伤害+1。你的回合内，"..
  "当你使用【杀】结算后，若此【杀】未造成伤害，本回合你手牌上限-1。",

  ["$os__piankuang1"] = "有延一人，足为我主克魏吞吴！",
  ["$os__piankuang2"] = "非我居功自傲，实为吴魏之辈不足一提！",
}

piankuang:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(piankuang.name) and data.card and data.card.trueName == "slash" then
      return player.room.logic:damageByCardEffect() and
        #player.room.logic:getActualDamageEvents(1, function (e)
          local damage = e.data
          return damage.from == player and damage.card ~= nil and damage.card.trueName == "slash"
        end, Player.HistoryTurn) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

piankuang:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(piankuang.name) and
      data.card and data.card.trueName == "slash" and not data.damageDealt and
      player.room.current == player
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, MarkEnum.MinusMaxCards.."-turn", 1)
  end,
})

return piankuang
