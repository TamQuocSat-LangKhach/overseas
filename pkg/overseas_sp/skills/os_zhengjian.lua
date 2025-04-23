local osZhengjian = fk.CreateSkill {
  name = "os__zhengjian"
}

Fk:loadTranslationTable{
  ["os__zhengjian"] = "征建",
  [":os__zhengjian"] = "游戏开始时，你选择一项：1.使用过非基本牌；2.获得过牌。其他角色的出牌阶段结束时，" ..
  "若其此阶段未完成“征建”要求的选项，其交给你一张牌，然后你可变更〖征建〗的选项。",

  ["@os__zhengjian_use"] = "征建使用非基",
  ["@os__zhengjian_obtain"] = "征建获得牌",
  ["@@os__zhengjian_use"] = "征建使用非基",
  ["@@os__zhengjian_obtain"] = "征建获得牌",
  ["os__zhengjian_use"] = "使用过非基本牌",
  ["os__zhengjian_obtain"] = "获得过牌",
  ["#os__zhengjian-ask"] = "征建：选择对其他角色的“征建”要求",
  ["#os__zhengjian_damage-ask"] = "征建：你可对 %src 造成1点伤害",
  ["#os__zhengjian-card"] = "征建：交给 %src 一张牌",
  ["#os__zhengjian_change-ask"] = "征建：你可变更“征建”要求",
  ["os__zhengjian_dmg"] = "造成1点伤害",

  ["$os__zhengjian1"] = "修建未成，皆因尔等懈怠。",
  ["$os__zhengjian2"] = "哼！何故建田不成！",
}

osZhengjian:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osZhengjian.name)
  end,
  on_cost = function(self, event, target, player)
    local choice = player.room:askToChoice(
      player,
      {
        choices = { "os__zhengjian_use", "os__zhengjian_obtain" },
        skill_name = osZhengjian.name,
        prompt = "#os__zhengjian-ask",
      }
    )
    event:setCostData(self, choice)
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@@" .. event:getCostData(self), 1)
    room:setPlayerMark(player, "@" .. event:getCostData(self), "0") --很怪
  end,
})

osZhengjian:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    if target.phase ~= Player.Play or not player:hasSkill(osZhengjian.name) or target == player then
      return false
    end
    return
      (
        (
          player:getMark("@os__zhengjian_use") ~= 0 and
          target:getMark("_os__zhengjian_use-phase") == 0
        ) or
        (
          player:getMark("@os__zhengjian_obtain") ~= 0 and
          target:getMark("_os__zhengjian_obtain-phase") == 0
        )
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osZhengjian.name
    local room = player.room
    local current = player:getMark("@os__zhengjian_use") ~= 0 and "@os__zhengjian_use" or "@os__zhengjian_obtain"
    local invoke = false
    if player:usedSkillTimes("os__zhongchi", Player.HistoryGame) > 0 then
      if
        room:askToChoice(
          player,
          {
            choices = { "os__zhengjian_dmg", "Cancel" },
            skill_name = skillName,
            prompt = "#os__zhengjian_damage-ask:" .. target.id,
          }
        ) ~= "Cancel"
      then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = skillName,
        }
        invoke = true
      end
    elseif not target:isNude() then
      local cid = room:askToCards(
        target,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          prompt = "#os__zhengjian-card:" .. player.id,
          cancelable = false,
        }
      )[1]
      invoke = true
      if player:getMark("@" .. current) > 0 then room:setPlayerMark(player, "@" .. current, 0) end
      room:setPlayerMark(player, current, tonumber(player:getMark(current)) + 1) --！
      room:moveCardTo(cid, Player.Hand, player, fk.ReasonGive, skillName, nil, false, target)
    end
    if invoke then
      local choice = current == "@os__zhengjian_use" and "os__zhengjian_obtain" or "os__zhengjian_use"
      local result = room:askToChoice(
        player,
        {
          choices = { choice, "Cancel" },
          skill_name = skillName,
          prompt = "#os__zhengjian_change-ask",
        }
      )
      if result ~= "Cancel" then
        room:setPlayerMark(player, "@" .. result, player:getMark(current))
        room:setPlayerMark(player, current, 0)
      end
    end
  end,
})

osZhengjian:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and data.card.type ~= Card.TypeBasic
  end,
  on_refresh = function(self, event, target, player)
    player.room:addPlayerMark(player, "_os__zhengjian_use-phase", 1)
  end,
})

osZhengjian:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.Play then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player)
    player.room:addPlayerMark(player, "_os__zhengjian_obtain-phase", 1)
  end,
})

return osZhengjian
