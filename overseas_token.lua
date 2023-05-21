local extension = Package("overseas_token", Package.CardPack)
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_token"] = "国际服衍生牌",
}

local moonSpearSkill = fk.CreateTriggerSkill{
  name = "#moon_spear_skill",
  attached_equip = "moon_spear",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") ~= 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local use =  player.room:askForUseCard(player, "slash", nil, "#moon_spear_skill-ask", true)
    if use then
      self.cost_data = use
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
    room:useCard(self.cost_data)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") > 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_moon_spear-turn")
  end,
}
Fk:addSkill(moonSpearSkill)
local moonSpear = fk.CreateWeapon{
  name = "&moon_spear",
  suit = Card.Diamond,
  number = 12,
  attack_range = 3,
  equip_skill = moonSpearSkill,
}
extension:addCard(moonSpear)
Fk:loadTranslationTable{
  ["moon_spear"] = "银月枪",
  ["#moon_spear_skill"] = "银月枪",
  [":moon_spear"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：当你于其他角色的回合中第一次失去牌后，你可使用【杀】。",
  ["#moon_spear_skill-ask"] = "银月枪：你可使用【杀】",
}

return extension