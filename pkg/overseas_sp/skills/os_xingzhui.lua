local osXingzhui = fk.CreateSkill {
  name = "os__xingzhui"
}

Fk:loadTranslationTable{
  ["os__xingzhui"] = "星坠",
  [":os__xingzhui"] = "出牌阶段限一次，你可以失去1点体力并<a href='os__shifa_href'>施法</a>X=1~3回合：亮出牌堆顶2X张牌，" ..
  "若其中有黑色牌，则你可令一名其他角色获得这些黑色牌，若这些牌的数量不小于X，则你对其造成X点雷电伤害。",

  ["@os__xingzhui"] = "星坠",
  ["#os__xingzhui-ask2"] = "星坠：你可令一名其他角色获得其中的黑色牌，然后对其造成 %arg 点雷电伤害",
  ["#os__xingzhui-ask"] = "星坠：你可令一名其他角色获得其中的黑色牌",

  ["$os__xingzhui1"] = "中宫黯弱，紫宫当明。",
  ["$os__xingzhui2"] = "星坠如雨，月掩轩辕。",
}

-- Active Skill Effect
osXingzhui:addEffect("active", {
  can_use = function(self, player)
    return player:usedSkillTimes(osXingzhui.name, Player.HistoryPhase) < 1 and player:getMark("@os__xingzhui") == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  interaction = UI.Spin { from = 1, to = 3 },
  on_use = function(self, room, effect)
    local num = self.interaction.data
    if not num then return false end -- 权宜，ai
    local player = effect.from
    room:loseHp(player, 1, osXingzhui.name)
    if player:isAlive() then
      room:setPlayerMark(player, "@os__xingzhui", num .. "-" .. num)
    end
  end,
})

-- Trigger Skill Effect
osXingzhui:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__xingzhui") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osXingzhui.name
    local room = player.room
    local nums = string.split(player:getMark("@os__xingzhui"), "-")
    local num = nums[1]
    local num2 = tonumber(nums[2])
    num2 = num2 - 1
    if num2 > 0 then
      room:setPlayerMark(player, "@os__xingzhui", num .. "-" .. tostring(num2))
    else
      room:notifySkillInvoked(player, skillName)
      player:broadcastSkillInvoke(skillName)

      room:setPlayerMark(player, "@os__xingzhui", 0)
      num = tonumber(num)
      local cids = room:getNCards(2 * num)
      room:turnOverCardsFromDrawPile(player, cids, skillName)
      room:delay(2000)

      local cards = table.filter(cids, function(cid) return Fk:getCardById(cid).color == Card.Black end)
      local black = #cards

      if black > 0 then
        local tos = room:askToChoosePlayers(
          player,
          {
            targets = room:getOtherPlayers(player, false),
            min_num = 1,
            max_num = 1,
            prompt = black >= num and "#os__xingzhui-ask2:::" .. tostring(num) or "#os__xingzhui-ask",
            skill_name = skillName,
          }
        )
        if #tos > 0 then
          to = tos[1]
          room:obtainCard(to, cards, true, fk.ReasonPrey, to, skillName)

          if black >= num then
            room:damage{
              from = player,
              to = to,
              damage = num,
              damageType = fk.ThunderDamage,
              skillName = skillName,
            }
          end
        end
      end

      room:cleanProcessingArea(cids)
    end
  end,
})

return osXingzhui
