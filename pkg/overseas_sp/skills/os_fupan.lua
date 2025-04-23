local osFupan = fk.CreateSkill {
  name = "os__fupan"
}

Fk:loadTranslationTable{
  ["os__fupan"] = "复叛",
  [":os__fupan"] = "当你造成或受到伤害后，你可摸X张牌（X为伤害值），然后交给一名其他角色一张牌。" ..
  "若你未以此法交给过其牌，你摸两张牌；否则，你可对其造成1点伤害，然后你不能再以此法交给其牌。",

  ["#os__fupan-give"] = "复叛：交给一名其他角色一张牌",
  ["os__fupan_dmg"] = "对%dest造成1点伤害，然后不能再以此法交给其牌",
  ["#os__fupan_tip_once"] = "可对其造成伤害",
  ["#os__fupan_tip_notyet"] = "你摸两张牌",

  ["$os__fupan1"] = "胜者为王，吾等……无话可说……",
  ["$os__fupan2"] = "今乱平阳之地，汉人如何可防？",
  ["$os__fupan3"] = "此为吾等，复兴匈奴之良机！",
}

local osFupanSpec = {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osFupan.name
    local room = player.room
    player:drawCards(data.damage, skillName)
    if not player:isAlive() then
      return false
    end

    local os__fupan_invalid = player:getTableMark("_os__fupan_invalid")
    local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not table.contains(os__fupan_invalid, p.id)
    end)
    if #availableTargets == 0 or player:isNude() then
      return false
    end

    local plist, cid = room:askToChooseCardsAndPlayers(
      player,
      {
        min_card_num = 1,
        max_card_num = 1,
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__fupan-give",
        skill_name = skillName,
        target_tip_name = "os__fupan_tip",
        cancelable = false,
      }
    )
    local to = plist[1]
    room:moveCardTo(cid, Player.Hand, to, fk.ReasonGive, skillName, nil, false, player)

    if not player:isAlive() then
      return false
    end

    local toId = to.id
    local targetedFirstTime = table.contains(player:getTableMark("_os__fupan_once"), toId)

    if not targetedFirstTime then
      room:addTableMark(player, "_os__fupan_once", toId)
      player:drawCards(2, skillName)
    elseif room:askToChoice(
        player, {
          choices = { "os__fupan_dmg::" .. toId, "Cancel" },
          skill_name = skillName,
        }
      ) ~= "Cancel"
    then
      table.insertIfNeed(os__fupan_invalid, toId)
      room:setPlayerMark(player, "_os__fupan_invalid", os__fupan_invalid)
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
}

osFupan:addEffect(fk.Damage, osFupanSpec)

osFupan:addEffect(fk.Damaged, osFupanSpec)

osFupan:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "_os__fupan_once", 0)
  room:setPlayerMark(player, "_os__fupan_invalid", 0)
end)

Fk:addTargetTip{
  name = "os__fupan_tip",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    return table.contains(player:getTableMark("_os__fupan_once"), to_select.id) and "#os__fupan_tip_once" or "#os__fupan_tip_notyet"
  end,
}

return osFupan
