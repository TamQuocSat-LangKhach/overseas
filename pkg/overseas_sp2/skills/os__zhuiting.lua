local os__zhuiting = fk.CreateSkill {
  name = "os__zhuiting$"
}

Fk:loadTranslationTable{
  ['os__zhuiting_other&'] = '坠廷',
}

os__zhuiting:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if (player.kingdom == "qun" or player.kingdom == "wei") and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(skill.name, true)
    end) then
      room:handleAddLoseSkills(player, skill.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. skill.attached_skill_name, nil, false, true)
    end
  end,
})

os__zhuiting:addEffect("on_acquire", {
  on_acquire = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and (p.kingdom == "qun" or p.kingdom == "wei") then
        room:handleAddLoseSkills(p, skill.attached_skill_name, nil, false, true)
      end
    end
  end,
})

return os__zhuiting
