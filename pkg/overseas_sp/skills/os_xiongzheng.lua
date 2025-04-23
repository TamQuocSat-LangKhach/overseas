local osXiongzheng = fk.CreateSkill {
  name = "os__xiongzheng"
}

Fk:loadTranslationTable{
  ["os__xiongzheng"] = "雄争",
  [":os__xiongzheng"] = "每轮开始时，你可选择一名未被此技能选择过的角色。若如此做，则本轮结束时，你可选择一项：" ..
  "1. 视为依次对任意名本轮未对其造成过伤害的其他角色使用一张【杀】；2. 令任意名本轮对其造成过伤害的角色摸两张牌。",

  ["#os__xiongzheng-ask"] = "你可对一名未被“雄争”选择过的角色发动“雄争”",
  ["#os__xiongzheng_judge"] = "雄争",
  ["@os__xiongzheng-round"] = "雄争",
  ["os__xiongzheng_slash"] = "视为对任意名本轮未对“雄争”角色造成伤害的其他角色使用【杀】",
  ["os__xiongzheng_draw"] = "令任意名本轮对对“雄争”角色造成过伤害的角色摸两张牌",
  ["#os__xiongzheng-slash"] = "选择任意名角色，视为分别对这些角色使用【杀】",
  ["#os__xiongzheng-draw"] = "选择任意名角色，各摸两张牌",

  ["$os__xiongzheng1"] = "西凉男儿，怀天下之志！",
  ["$os__xiongzheng2"] = "金戈铁马，争乱世之雄！",
}

osXiongzheng:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return
      player:hasSkill(osXiongzheng.name) and
      table.find(player.room.alive_players, function(p)
        return p:getMark("_os__xiongzheng") == 0
      end)
  end,
  on_cost = function(self, event, target, player)
    local targets = table.filter(player.room.alive_players, function(p)
      return (p:getMark("_os__xiongzheng") == 0)
    end)
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__xiongzheng-ask",
      skill_name = osXiongzheng.name,
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = event:getCostData(self)
    room:setPlayerMark(player, "@" .. osXiongzheng.name .. "-round", to.general)
    room:addPlayerMark(to, "_os__xiongzheng", 1)
    room:addPlayerMark(to, "_os__xiongzheng-round", 1)
  end,
})

osXiongzheng:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      data.to and
      data.to:getMark("_os__xiongzheng-round") > 0 and
      player:getMark("_os__xiongzheng_damage-round") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__xiongzheng_damage-round", 1)
  end,
})

osXiongzheng:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return
      target:getMark("_os__xiongzheng-round") > 0 and 
      data.damage and
      data.damage.from and
      data.damage.from == player and
      player:getMark("_os__xiongzheng_damage-round") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__xiongzheng_damage-round", 1)
  end,
})

osXiongzheng:addEffect(fk.RoundEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player)
    return player:getMark("@os__xiongzheng-round") ~= 0
  end,
  on_cost = function(self, event, target, player)
    local choices = { "os__xiongzheng_slash", "os__xiongzheng_draw", "Cancel" }
    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osXiongzheng.name,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osXiongzheng.name
    local room = player.room
    local choice = event:getCostData(self)
    player:broadcastSkillInvoke(skillName)

    if choice == "os__xiongzheng_slash" then
      local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
        return p:getMark("_os__xiongzheng_damage-round") == 0
      end)
      local targets = room:askToChoosePlayers(
        player,
        {
          targets = availableTargets,
          min_num = 1,
          max_num = #availableTargets,
          prompt = "#os__xiongzheng-slash",
          skill_name = skillName,
        }
      )
      if #targets > 0 then
        room:notifySkillInvoked(player, skillName)
        local slash = Fk:cloneCard("slash")
        slash.skillName = skillName

        room:sortByAction(targets)
        for _, p in ipairs(targets) do
          if not player:isAlive() then
            break
          end
          if p:isAlive() then
            room:useVirtualCard("slash", nil, player, { p }, skillName, true)
          end
        end
      end
    else
      local availableTargets = table.filter(room.alive_players, function(p)
        return p:getMark("_os__xiongzheng_damage-round") > 0
      end)
      local targets = room:askToChoosePlayers(
        player,
        {
          targets = availableTargets,
          min_num = 1,
          max_num = #availableTargets,
          prompt = "#os__xiongzheng-draw",
          skill_name = skillName,
        }
      )
      if #targets > 0 then
        room:notifySkillInvoked(player, "os__xiongzheng", "drawcard")
        room:sortByAction(targets)
        table.forEach(targets, function(p)
          p:drawCards(2, skillName)
        end)
      end
    end
  end,
})

return osXiongzheng
