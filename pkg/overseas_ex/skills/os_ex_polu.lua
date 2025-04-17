local osExPolu = fk.CreateSkill {
  name = "os_ex__polu",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["os_ex__polu"] = "破虏",
  [":os_ex__polu"] = "主公技，当吴势力角色杀死一名角色或死亡后，你可令任意名角色各摸X张牌（X为你发动过此技能的次数+1）。",

  ["#os_ex__polu"] = "破虏：你可选择任意名角色，令其各摸 %arg 张牌",
  ["@os_ex__polu"] = "破虏",

  ["$os_ex__polu1"] = "义定四野，武匡海内。", -- 其实是给英魂的
  ["$os_ex__polu2"] = "江东男儿，皆胸怀匡扶天下之志。",
}

osExPolu:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osExPolu.name) and
      (
        (data.damage and data.damage.from and data.damage.from.kingdom == "wu") or
        target.kingdom == "wu"
      )
  end,
  on_trigger = function(self, event, target, player, data)
    if target.kingdom == "wu" then
      self:doCost(event, target, player, data)
    end
    if data.damage and data.damage.from and data.damage.from.kingdom == "wu" then
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player)
    ---@type string
    local skillName = osExPolu.name
    local alivePlayers = player.room:getAlivePlayers(false)
    local targets = player.room:askToChoosePlayers(
      player,
      {
        targets = alivePlayers,
        min_num = 1,
        max_num = #alivePlayers,
        prompt = "#os_ex__polu:::" .. player:usedSkillTimes(skillName, Player.HistoryGame) + 1,
        skill_name = skillName,
      }
    )
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local targets = event:getCostData(self)
    local room = player.room
    room:sortByAction(targets)
    room:addPlayerMark(player, "@os_ex__polu")
    for _, p in ipairs(targets) do
      if p:isAlive() then
        p:drawCards(player:usedSkillTimes(osExPolu.name, Player.HistoryGame))
      end
    end
  end,
})

return osExPolu
