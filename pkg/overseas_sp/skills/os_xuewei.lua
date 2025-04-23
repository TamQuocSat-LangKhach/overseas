local osXuewei = fk.CreateSkill {
  name = "os__xuewei"
}

Fk:loadTranslationTable{
  ["os__xuewei"] = "血卫",
  [":os__xuewei"] = "每轮限一次，其他角色A的出牌阶段开始时，你可选择另一名其他角色B并令A选择一项：" ..
  "1. 直到本回合结束，其不能对B使用【杀】且手牌上限-2；2. 视为你对其使用一张【决斗】。",

  ["#os__xuewei-ask"] = "你可选择一名除 %dest 以外的其他角色，发动“血卫”",
  ["os__xuewei_defence"] = "直到本回合结束，你不能对 %dest 使用【杀】且手牌上限-2",
  ["os__xuewei_duel"] = "视为 %src 对你使用一张【决斗】",
  ["#os__xuewei_defence"] = "%from 由于“%arg”，不能对 %to 使用【杀】且手牌上限-2",

  ["$os__xuewei1"] = "吾主之尊，岂容尔等贼寇近前？",
  ["$os__xuewei2"] = "血佑忠魂，身卫英主。",
}

osXuewei:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    return
      target ~= player and
      player:hasSkill(osXuewei.name) and
      target.phase == Player.Play and
      player:usedSkillTimes(osXuewei.name, Player.HistoryRound) < 1 and
      #player.room:getOtherPlayers(player, false) > 1
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local other_players = table.filter(room:getOtherPlayers(target, false), function(p)
      return p ~= player
    end)

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = other_players,
        min_num = 1,
        max_num = 1,
        prompt = "#os__xuewei-ask::" .. target.id,
        skill_name = osXuewei.name,
      }
    )

    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osXuewei.name
    local room = player.room
    local to = event:getCostData(self)
    local all_choices = { "os__xuewei_defence::" .. to.id, "os__xuewei_duel:" .. player.id }
    local choices = table.simpleClone(all_choices)
    local duel = Fk:cloneCard("duel")
    duel.skillName = skillName
    if not player:canUseTo(duel, target) then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(
      target,
      {
        choices = choices,
        skill_name = skillName,
        all_choices = all_choices,
      }
    )

    if choice:startsWith("os__xuewei_defence") then
      room:addTableMarkIfNeed(target, "_os__xuewei_defence-turn", to.id)
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
      room:sendLog{
        type = "#os__xuewei_defence",
        from = target.id,
        to = { to.id },
        arg = skillName,
      }
    else
      ---@type UseCardDataSpec
      local new_use = {
        from = player,
        tos = { target },
        card = duel,
      }

      room:useCard(new_use)
    end
  end,
})

osXuewei:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if table.contains(from:getTableMark("_os__xuewei_defence-turn"), to.id) then
      return card.trueName == "slash"
    end
  end,
})

return osXuewei
