local os__shanghe = fk.CreateSkill {
  name = "os__shanghe"
}

Fk:loadTranslationTable{
  ['os__shanghe'] = '觞贺',
  [':os__shanghe'] = '限定技，当你进入濒死状态时，你可令所有其他角色各交给你一张牌，若其中没有【酒】，你将体力回复至1点。',
  ['$os__shanghe1'] = '今使海内回心，望风而愿治，皆明公之功也。',
  ['$os__shanghe2'] = '明公平定兵乱，使百姓可安，粲当奉觞以贺之。',
}

os__shanghe:addEffect(fk.EnterDying, {
  anim_type = "support",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__shanghe) and player:usedSkillTimes(os__shanghe.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local not_include = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isNude() then
        local id = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          skill_name = os__shanghe.name,
          cancelable = false
        })[1]
        if not_include and Fk:getCardById(id).trueName == "analeptic" then
          not_include = false
        end
        room:moveCardTo(id, Player.Hand, player, fk.ReasonGive, os__shanghe.name, nil, false)
      end
    end

    if not_include and not player.dead and player.hp < 1 then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = os__shanghe.name,
      })
    end
  end,
})

return os__shanghe
