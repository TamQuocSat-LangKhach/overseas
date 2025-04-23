local osMutao = fk.CreateSkill {
  name = "os__mutao"
}

Fk:loadTranslationTable{
  ["os__mutao"] = "募讨",
  [":os__mutao"] = "出牌阶段限一次，你可选择一名角色，令其将手牌中的（系统选择）每一张【杀】依次交给由其下家开始的除其以外的角色，" ..
  "然后其对最后一名角色造成X点伤害（X为最后一名角色手牌中【杀】的数量且至多为3）。",

  ["$os__mutao1"] = "董贼暴乱，天下定当奋节讨之！",
  ["$os__mutao2"] = "募州郡义士，讨祸国逆贼！",
}

osMutao:addEffect("active", {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(osMutao.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isKongcheng() and to_select:getNextAlive() ~= to_select
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osMutao.name
    local target = effect.tos[1]
    local to = target
    while true do
      local cids = table.filter(target:getCardIds("h"), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cids < 1 then
        break
      end

      to = to:getNextAlive()
      if to == target then to = to:getNextAlive() end
      room:moveCardTo(table.random(cids), Player.Hand, to, fk.ReasonGive, skillName, nil, false, target)
    end
    local num = math.min(#table.filter(to:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end), 3)
    if num > 0 then
      room:damage{
        from = target,
        to = to,
        damage = num,
        skill_name = skillName,
      }
    end
  end,
})

return osMutao
