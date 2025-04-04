local os__wuhun = fk.CreateSkill {
  name = "os__wuhun"
}

Fk:loadTranslationTable{
  ['os__wuhun'] = '武魂',
  ['@os__nightmare'] = '梦魇',
  ['os__wuhun_judge'] = '判定，若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色失去X点体力（X为其“梦魇”数）',
  ['#os__wuhun-targets'] = '武魂：选择至少一名有“梦魇”的角色，各失去X点体力（X为其“梦魇”数）',
  [':os__wuhun'] = '锁定技，①当你受到1点伤害后，伤害来源获得1枚“梦魇”。②当你对有“梦魇”的角色造成伤害后，其获得1枚“梦魇”。③当你死亡时，你可判定：若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色，这些角色失去X点体力（X为其“梦魇”数）。',
  ['$os__wuhun1'] = '追你到天涯海角！',
  ['$os__wuhun2'] = '我看你怎么跑！',
}

os__wuhun:addEffect(fk.Damaged, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__wuhun.name, false, true) then
      return data.from and not data.from.dead and not player.dead
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(data.from, "@os__nightmare", data.damage)
  end,
})

os__wuhun:addEffect(fk.Damage, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__wuhun.name, false, true) then
      return data.to and data.to:getMark("@os__nightmare") > 0 and not data.to.dead and not player.dead
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(data.to, "@os__nightmare", 1)
  end,
})

os__wuhun:addEffect(fk.Death, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__wuhun.name, false, true) then
      local availableTargets = table.map(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@os__nightmare") > 0
      end)
      if #availableTargets > 0 then
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:askToChoice(player, {
      choices = {"os__wuhun_judge", "Cancel"},
      skill_name = os__wuhun.name,
    }) == "os__wuhun_judge" then
      local judge = {
        who = player,
        reason = os__wuhun.name,
        pattern = "peach,god_salvation|.",
      }
      room:judge(judge)
      if judge.card.name == "peach" or judge.card.name == "god_salvation" then return false end

      local availableTargets = table.map(
        table.filter(player.room:getOtherPlayers(player, false), function(p)
          return p:getMark("@os__nightmare") > 0
        end),
        Util.IdMapper
      )
      if #availableTargets == 0 then return false end

      local targets = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = 99,
        prompt = "#os__wuhun-targets",
        skill_name = os__wuhun.name,
        cancelable = false
      })
      if #targets > 0 then
        room:sortPlayersByAction(targets)
        for _, id in ipairs(Util.IdListToTable(targets)) do
          local p = room:getPlayerById(id)
          room:loseHp(p, p:getMark("@os__nightmare"), os__wuhun.name)
        end
      end
    end
  end,
})

return os__wuhun
