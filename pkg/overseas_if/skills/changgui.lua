local changgui = fk.CreateSkill {
  name = "os__changgui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__changgui"] = "怅归",
  [":os__changgui"] = "锁定技，结束阶段，若你的体力值为全场最低，则你<a href='os_tuihuan_zhugeliang'>“退幻”</a>并将体力上限调整至体力值。",

  ["os_tuihuan_zhugeliang"] = "变身为表形态：<br>" ..
  "<b>北定</b>：一名角色的准备阶段，你可以声明并记录至多X种未被〖北定〗记录过的基本牌或普通锦囊牌牌名。" ..
  "若如此做，此回合的弃牌阶段结束时，你依次视为使用本回合记录的牌（无距离限制），若此牌的目标不包含当前回合角色，" ..
  "其摸一张牌（X为你的体力值）。<br>" ..
  "<b>竭虑</b>：锁定技，一名角色的回合结束时，若你于本回合内未对其使用过牌，则你失去1点体力；当你受到1点伤害或失去1点体力后，" ..
  "若你的体力上限小于7，则你加1点体力上限。" ..
  "<b>魂游</b>：限定技，当你处于濒死状态时，你可以将体力回复至1点，本回合防止你受到的伤害和体力流失。" ..
  "此回合结束时，你<a href='os_ruhuan_zhugeliang'>“入幻”</a>并获得一个额外的回合。",

  ["$os__changgui1"] = "隆中鱼水，永安星落，数载恍然隔世。",
  ["$os__changgui2"] = "铁马冰河，金台临望，倏醒方叹无功。",
}

changgui:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(changgui.name) and player.phase == Player.Finish and
      table.every(player.room.alive_players, function(p)
        return p.hp >= player.hp
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-os_huan__beiding|-os_huan__jielv|-os__huanji|-os__changgui|os__beiding|os__jielv|os__hunyou",
      nil, true, false)
    if player.general == "os_if_huan__zhugeliang" then
      room:setPlayerProperty(player, "general", "os_if__zhugeliang")
    end
    if player.deputyGeneral == "os_if_huan__zhugeliang" then
      room:setPlayerProperty(player, "deputyGeneral", "os_if__zhugeliang")
    end
    room:changeMaxHp(player, player.hp - player.maxHp)
  end,
})

return changgui
