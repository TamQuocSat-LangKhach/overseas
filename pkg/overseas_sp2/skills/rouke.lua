local rouke = fk.CreateSkill {
  name = "os__rouke"
}

Fk:loadTranslationTable{
  ['os__rouke'] = '柔克',
  [':os__rouke'] = '锁定技，当你在摸牌阶段外获得不少于两张牌时，你摸一张牌。',
  ['$os__rouke1'] = '宽以待人，柔能克刚，则英雄莫敌。',
  ['$os__rouke2'] = '务崇宽惠，顺天命以行诛。',
}

rouke:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(rouke.name) and player.phase ~= Player.Draw then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand and #move.moveInfo > 1 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, rouke.name)
  end,
})

return rouke
