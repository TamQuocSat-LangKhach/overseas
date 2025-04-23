local osBaonueMark = fk.CreateSkill {
  name = "#os__baonue_mark",
}

Fk:loadTranslationTable{
  ["@os__baonue"] = "暴虐值",
}

local osBaonueMarkSpec = {
  can_refresh = function(self, event, target, player, data)
    local osBaonueSkills = {
      "os__juntun",
      "os__xiafeng",
      "os__xiongxi",
    }

    return
      target == player and
      table.find(osBaonueSkills, function(skill) return player:hasSkill(skill, true) end) and
      player:getMark("@os__baonue") < 5
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__baonue")
  end,
}

osBaonueMark:addEffect(fk.Damage, osBaonueMarkSpec)

osBaonueMark:addEffect(fk.Damaged, osBaonueMarkSpec)

return osBaonueMark
