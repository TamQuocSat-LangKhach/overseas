local osLuannian = fk.CreateSkill {
  name = "os__luannian",
  tags = { Skill.Lord },
  attached_skill_name = "os__luannian_other&",
}

Fk:loadTranslationTable{
  ["os__luannian"] = "乱年",
  [":os__luannian"] = "主公技，其他群势力角色出牌阶段限一次，其可弃置X张牌对“雄争”角色造成1点伤害（X为此技能本轮发动的次数+1）。",

  ["$os__luannian1"] = "凶年荒岁，当兴乱自保！",
  ["$os__luannian2"] = "天下大势，分分合合。",
}

osLuannian:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player)
    return target == player
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(osLuannian.name, true)
    end) then
      room:handleAddLoseSkills(player, osLuannian.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. osLuannian.attached_skill_name, nil, false, true)
    end
  end,
})

osLuannian:addAcquireEffect(function(self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    local oper = p.kingdom == "qun" and "" or "-"
    room:handleAddLoseSkills(p, oper .. osLuannian.attached_skill_name, nil, false, true)
  end
end)

return osLuannian
