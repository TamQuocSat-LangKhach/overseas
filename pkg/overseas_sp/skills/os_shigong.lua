local osShigong = fk.CreateSkill {
  name = "os__shigong",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__shigong"] = "示恭",
  [":os__shigong"] = "限定技，当你于回合外进入濒死状态时，你可令当前回合者选择一项：1. 增加1点体力上限，" ..
  "回复1点体力，摸一张牌，令你体力回复至体力上限；2. 弃置X张手牌（X为其当前体力值），令你体力回复至1点。",

  ["os__shigong_max"] = "增加1点体力上限，回复1点体力，摸一张牌，令%src体力回复至体力上限",
  ["os__shigong_dis"] = "弃置%arg张手牌，令%src体力回复至1点",

  ["$os__shigong1"] = "冀州安定，此司空之功也……",
  ["$os__shigong2"] = "妾当自缚，以示诚心。",
}

osShigong:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return
      player == target and
      player:hasSkill(osShigong.name) and
      player.room.current and
      player.room.current ~= player and
      player:usedSkillTimes(osShigong.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osShigong.name
    local room = player.room
    local current = room.current
    local all_choices = { "os__shigong_max:" .. player.id, "os__shigong_dis:" .. player.id .. "::" .. current.hp }
    local choices = table.simpleClone(all_choices)
    if #table.filter(player:getCardIds("h"), function(id) return not player:prohibitDiscard(id) end) < current.hp then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(
      current,
      {
        choices = choices,
        skill_name = skillName,
        all_choices = all_choices,
      }
    )

    if choice:startsWith("os__shigong_max") then
      room:changeMaxHp(current, 1)
      if current:isAlive() then
        room:recover{
          who = current,
          num = 1,
          recoverBy = current,
          skillName = skillName,
        }
        if current:isAlive() then
          current:drawCards(1, skillName)
        end
      end
      if player:isAlive() then
        room:recover{
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = skillName,
        }
      end
    else
      room:askToDiscard(
        current,
        {
          min_num = current.hp,
          max_num = current.hp,
          skill_name = skillName,
          cancelable = false,
        }
      )
      if player:isAlive() then
        room:recover{
          who = player,
          num = 1 - player.hp,
          recoverBy = player,
          skillName = skillName,
        }
      end
    end
  end,
})

return osShigong
