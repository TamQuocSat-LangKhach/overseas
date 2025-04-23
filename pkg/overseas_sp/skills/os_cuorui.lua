local osCuorui = fk.CreateSkill {
  name = "os__cuorui",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__cuorui"] = "挫锐",
  [":os__cuorui"] = "限定技，准备阶段开始时，你可将手牌摸至X张（X为全场最大的手牌数，至多摸五张），" ..
  "废除判定区。若你发动过〖挫锐〗，你可选择一名其他角色，对其造成1点伤害。",

  ["@@os__cuorui"] = "挫锐",
  ["#os__cuorui_dmg-ask"] = "挫锐：你可摸 %arg 张牌，废除判定区，然后可以选择一名其他角色，对其造成1点伤害",
  ["#os__cuorui-ask"] = "挫锐：你可摸 %arg 张牌，废除判定区",
  ["#os__cuorui-target"] = "挫锐：你可对一名其他角色造成1点伤害",

  ["$os__cuorui1"] = "区区乌合之众，如何困得住我？！",
  ["$os__cuorui2"] = "今日就让你见识见识老牛的厉害！",
}

osCuorui:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return
      player == target and
      player:hasSkill(osCuorui.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(osCuorui.name, Player.HistoryGame) < 1 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getHandcardNum() > player:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local num = player:getHandcardNum()
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p:getHandcardNum() > num then
        num = p:getHandcardNum()
      end
    end
    num = math.min(num - player:getHandcardNum(), 5)

    if
      room:askToSkillInvoke(
        player,
        {
          skill_name = osCuorui.name,
          prompt = player:getMark("@@os__cuorui") > 0 and "#os__cuorui_dmg-ask:::" .. num or "#os__cuorui-ask:::" .. num,
        }
      )
    then
      event:setCostData(self, num)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osCuorui.name
    local room = player.room
    player:drawCards(event:getCostData(self), skillName)
    if not player:isAlive() then
      return false
    end

    room:abortPlayerArea(player, { Player.JudgeSlot })
    room:addPlayerMark(player, "@@os__cuorui")
    if player:getMark("@@os__cuorui") > 1 and player:isAlive() then
      local victim = room:askToChoosePlayers(
        player,
        {
          targets = room:getOtherPlayers(player, false),
          min_num = 1,
          max_num = 1,
          prompt = "#os__cuorui-target",
          skill_name = skillName,
        }
      )
      if #victim == 0 then
        return false
      end

      room:damage{
        from = player,
        to = victim[1],
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return osCuorui
