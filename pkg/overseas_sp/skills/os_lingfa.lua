local osLingfa = fk.CreateSkill {
  name = "os__lingfa"
}

Fk:loadTranslationTable{
  ["os__lingfa"] = "令法",
  [":os__lingfa"] = "每轮开始时，若当前轮数不大于2，你可令第X项效果对所有有牌的其他角色生效（X为当前轮数）：" ..
  "1. 当使用【杀】时，弃置一张牌，否则你对其造成1点伤害；2. 当使用【桃】结算结束后，交给你一张牌，" ..
  "否则你对其造成1点伤害。若当前轮数大于2，则你失去此技能，获得〖治暗〗。",

  ["@os__lingfa"] = "令法",
  ["#os__lingfa_use"] = "令法",
  ["#os__lingfa-discard"] = "令法：弃置一张牌，否则受到 %dest 造成的1点伤害",
  ["#os__lingfa-give"] = "令法：交给 %dest 一张牌，否则受到其造成的1点伤害",

  ["$os__lingfa1"] = "吾明令在此，汝何以犯之？",
  ["$os__lingfa2"] = "法不阿贵，绳不挠曲！",
}

osLingfa:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(osLingfa.name) then
      return false
    end

    local room = player.room
    local num = room:getBanner("RoundCount")
    if num <= 2 then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)

      return #targets > 0
    end

    return num > 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:getBanner("RoundCount") > 2 or room:askToSkillInvoke(player, { skill_name = osLingfa.name })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local round = room:getBanner("RoundCount")
    if round <= 2 then
      local mark = round == 1 and "slash" or "peach"
      table.forEach(table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end), function(p)
        room:setPlayerMark(p, "@os__lingfa", mark)
      end)
    else
      if table.every(room:getOtherPlayers(player, false), function(p)
        return not p:hasSkill(self)
      end) then
        table.forEach(room.alive_players, function(p)
          room:setPlayerMark(p, "@os__lingfa", 0)
        end)
      end
      room:handleAddLoseSkills(player, "os__zhian|-os__lingfa", nil)
    end
  end,
})

osLingfa:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osLingfa.name) and
      target:getMark("@os__lingfa") == "slash" and
      data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osLingfa.name
    local room = player.room
    room:doIndicate(player, { target })
    local cids = room:askToDiscard(
      target,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        prompt = "#os__lingfa-discard::" .. player.id,
      }
    )
    if #cids == 0 then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

osLingfa:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osLingfa.name) and
      target:getMark("@os__lingfa") == "peach" and
      data.card.name == "peach"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osLingfa.name
    local room = player.room
    room:doIndicate(player, { target })
    local cids = room:askToCards(
      target,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        prompt = "#os__lingfa-give::" .. player.id,
      }
    )
    if #cids > 0 then
      room:moveCardTo(cids[1], Player.Hand, player, fk.ReasonGive, skillName, nil, false, target)
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return osLingfa
