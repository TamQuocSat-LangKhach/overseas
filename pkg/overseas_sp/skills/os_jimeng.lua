local osJimeng = fk.CreateSkill {
  name = "os__jimeng"
}

Fk:loadTranslationTable{
  ["os__jimeng"] = "急盟",
  [":os__jimeng"] = "出牌阶段限一次，你可获得一名其他角色区域内的一张牌，然后交给其一张牌。若其体力值不小于你，你摸一张牌。",

  ["#os__jimeng-card"] = "急盟：交给 %dest 一张牌",

  ["$os__jimeng1"] = "今日之言，皆是为保两国无虞。",
  ["$os__jimeng2"] = "天下之势已如水火，还望重修盟好。",
}

osJimeng:addEffect("active", {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(osJimeng.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isAllNude()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osJimeng.name
    local player = effect.from
    local target = effect.tos[1]
    local id = room:askToChooseCard(
      player,
      {
        target = target,
        flag = "hej",
        skill_name = skillName,
      }
    )
    room:obtainCard(player, id, false, fk.ReasonPrey, player, skillName)

    if not player:isAlive() or player:isNude() then
      return false
    end

    local c = room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        prompt = "#os__jimeng-card::" .. target.id,
        cancelable = false,
      }
    )[1]
    room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, skillName, nil, false, player)

    if target.hp >= player.hp and player:isAlive() then
      player:drawCards(1, skillName)
    end
  end,
})

return osJimeng
