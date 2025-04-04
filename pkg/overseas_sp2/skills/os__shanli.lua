local os__shanli = fk.CreateSkill {
  name = "os__shanli"
}

Fk:loadTranslationTable{
  ['os__shanli'] = '擅立',
  ['#os__shanli-ask'] = '擅立：选择一名角色，令其获得一个主公技',
  ['#os__shanli-skill'] = '擅立：选择一个主公技令 %src 获得',
  [':os__shanli'] = '觉醒技，准备阶段，若你对至少两名角色发动过〖景略〗，并且〖败移〗已发动，你减1点体力上限并选择一名角色，你从随机三个主公技中选择一个令其获得。',
  ['$os__shanli1'] = '荡尘涤污，重整河山，便在今日！',
  ['$os__shanli2'] = '效伊尹霍光，以返天下清明。',
}

os__shanli:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__shanli.name) and player:usedSkillTimes(os__shanli.name, Player.HistoryGame) == 0 and player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player)
    return player:usedSkillTimes(os__baiyi.name, Player.HistoryGame) > 0 and type(player:getMark("_os__jinglue")) == "table" and #player:getMark("_os__jinglue") > 1
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, -1)
    local target = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__shanli-ask",
      skill_name = os__shanli.name,
      cancelable = false
    })[1]

    local skills = {}
    for _, general in ipairs(Fk:getAllGenerals()) do
      for _, skill in ipairs(general.skills) do
        if skill.lordSkill then
          table.insertIfNeed(skills, skill.name)
        end
      end
    end

    if #skills > 0 then
      skills = table.random(skills, 3)
      local skillName = room:askToChoice(player, {
        choices = skills,
        skill_name = os__shanli.name,
        prompt = "#os__shanli-skill:" .. target,
        detailed = true
      })

      room:handleAddLoseSkills(room:getPlayerById(target), skillName, nil, true, false)
    end
  end,
})

return os__shanli
