local os__jimeng = fk.CreateSkill {
  name = "os__jimeng"
}

Fk:loadTranslationTable{
  ['os__jimeng'] = '急盟',
  ['#os__jimeng-card'] = '急盟：交给 %dest 一张牌',
  [':os__jimeng'] = '出牌阶段限一次，你可获得一名其他角色区域内的一张牌，然后交给其一张牌。若其体力值不小于你，你摸一张牌。',
  ['$os__jimeng1'] = '今日之言，皆是为保两国无虞。',
  ['$os__jimeng2'] = '天下之势已如水火，还望重修盟好。',
}

os__jimeng:addEffect('active', {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(os__jimeng.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "hej",
      skill_name = os__jimeng.name
    })
    room:obtainCard(effect.from, id, false)

    if player.dead or player:isNude() then return false end
    local c = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__jimeng.name,
      prompt = "#os__jimeng-card::" .. target.id
    })[1]
    room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, os__jimeng.name, nil, false, player.id)

    if target.hp >= player.hp and not player.dead then
      player:drawCards(1, os__jimeng.name)
    end
  end,
})

return os__jimeng
