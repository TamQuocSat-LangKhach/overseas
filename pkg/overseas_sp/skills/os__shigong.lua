local os__shigong = fk.CreateSkill {
  name = "os__shigong"
}

Fk:loadTranslationTable{
  ['os__shigong'] = '示恭',
  ['os__shigong_max'] = '增加1点体力上限，回复1点体力，摸一张牌，令%src体力回复至体力上限',
  ['os__shigong_dis'] = '弃置%arg张手牌，令%src体力回复至1点',
  [':os__shigong'] = '限定技，当你回合外进入濒死状态时，你可令当前回合者选择一项：1. 增加1点体力上限，回复1点体力，摸一张牌，令你体力回复至体力上限；2. 弃置X张手牌（X为其当前体力值），令你体力回复至1点。',
  ['$os__shigong1'] = '冀州安定，此司空之功也……',
  ['$os__shigong2'] = '妾当自缚，以示诚心。',
}

os__shigong:addEffect(fk.EnterDying, {
  anim_type = "support",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__shigong.name) and player.phase == Player.NotActive and player:usedSkillTimes(os__shigong.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local current = room.current
    local all_choices = {"os__shigong_max:" .. player.id, "os__shigong_dis:" .. player.id .. "::" .. current.hp}
    local choices = table.clone(all_choices)
    if current:getHandcardNum() < current.hp then 
      table.remove(choices, 2) 
    end
    local choice = room:askToChoice(current, {
      choices = choices,
      skill_name = os__shigong.name,
      all_choices = all_choices
    })

    if choice:startsWith("os__shigong_max") then
      room:changeMaxHp(current, 1)
      if not current.dead then
        room:recover{
          who = current,
          num = 1,
          recoverBy = current,
          skillName = os__shigong.name,
        }
        if not current.dead then
          current:drawCards(1, os__shigong.name)
        end
      end
      if not player.dead then
        room:recover{
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = os__shigong.name,
        }
      end
    else
      local discards = room:askToDiscard(current, {
        min_num = current.hp,
        max_num = current.hp,
        include_equip = false,
        skill_name = os__shigong.name,
        cancelable = false,
      })
      if not player.dead then
        room:recover{
          who = player,
          num = 1 - player.hp,
          recoverBy = player,
          skillName = os__shigong.name,
        }
      end
    end
  end,
})

return os__shigong
