local os__duoren = fk.CreateSkill {
  name = "os__duoren"
}

Fk:loadTranslationTable{
  ['os__duoren'] = '夺刃',
  ['@os__duoren'] = '夺刃',
  [':os__duoren'] = '当你杀死一名角色后，你可减1点体力上限，获得其除主公技以外的所有技能。当你对其他角色造成伤害令其进入濒死状态时，你失去以此法获得的技能。',
  ['$os__duoren1'] = '便以汝血，封汝之刀！',
  ['$os__duoren2'] = '血婆娑之剑，从不会沾无辜之血。',
}

os__duoren:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__duoren) and data.damage and data.damage.from == player 
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, -1)
    local skills = table.map(table.filter(target.player_skills, function(s)
      return s:isPlayerSkill(target) and not s.lordSkill
    end), Util.NameMapper) or {}
    local names = table.concat(skills, "|")
    room:handleAddLoseSkills(player, names, nil)
    room:setPlayerMark(player, "@os__duoren", target.general)
    room:setPlayerMark(player, "_os__duoren", names)
  end,
})

os__duoren:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player)
    return data.damage and data.damage.from and player:hasSkill(os__duoren) and data.damage.from == player and player:getMark("_os__duoren") ~= 0 and target ~= player
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local skills = string.split(player:getMark("_os__duoren"), "|")
    local names = table.map(skills, function(s)
      return "-" .. s
    end)
    room:handleAddLoseSkills(player, names, nil)
    room:setPlayerMark(player, "@os__duoren", 0)
    room:setPlayerMark(player, "_os__duoren", 0)
  end,
})

return os__duoren
