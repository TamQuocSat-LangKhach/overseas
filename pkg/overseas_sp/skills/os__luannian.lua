local os__luannian = fk.CreateSkill {
  name = "os__luannian$"
}

Fk:loadTranslationTable{
  ['os__luannian_other&'] = '乱年',
}

os__luannian:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player)
    return target == player
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(skill.name, true)
    end) then
      room:handleAddLoseSkills(player, skill.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. skill.attached_skill_name, nil, false, true)
    end
  end,
})

os__luannian:addEffect('acquire', {
  on_acquire = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.kingdom == "qun" then
        room:handleAddLoseSkills(p, skill.attached_skill_name, nil, false, true)
      end
    end
  end,
})

return os__luannian
